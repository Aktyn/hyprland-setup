use std::{
    sync::{Arc, Mutex},
    time::Duration,
};

use serde::Deserialize;
use tokio::sync::mpsc::{self, UnboundedReceiver, UnboundedSender};
use zbus::{
    Connection,
    fdo::{DBusProxy, RequestNameFlags, RequestNameReply},
    message::Header,
    names::WellKnownName,
    proxy,
    zvariant::{OwnedValue, Type},
};

const WATCHER_NAME: WellKnownName =
    WellKnownName::from_static_str_unchecked("org.kde.StatusNotifierWatcher");
const WATCHER_PATH: &str = "/StatusNotifierWatcher";

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct TrayItem {
    pub(crate) name: String,
    pub(crate) title: String,
    pub(crate) icon: Option<TrayIcon>,
    pub(crate) menu: Vec<TrayMenuEntry>,
    pub(crate) menu_path: String,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct TrayMenuEntry {
    pub(crate) id: i32,
    pub(crate) label: String,
    pub(crate) enabled: bool,
    pub(crate) children: Vec<TrayMenuEntry>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) enum TrayIcon {
    Name(String),
    Pixmap {
        width: u32,
        height: u32,
        data: Arc<Vec<u8>>,
    },
}

#[derive(Clone)]
pub(crate) struct TrayService {
    items: Arc<Mutex<Vec<TrayItem>>>,
    commands: UnboundedSender<TrayCommand>,
}

pub(crate) enum TrayCommand {
    Activate(String),
    ContextMenu(String),
    MenuItemClicked {
        name: String,
        menu_path: String,
        menu_id: i32,
    },
}

impl TrayService {
    pub(crate) fn new() -> (Self, UnboundedReceiver<TrayCommand>) {
        let (commands, receiver) = mpsc::unbounded_channel();
        (
            Self {
                items: Arc::new(Mutex::new(Vec::new())),
                commands,
            },
            receiver,
        )
    }

    pub(crate) fn snapshot(&self) -> Vec<TrayItem> {
        match self.items.lock() {
            Ok(items) => items.clone(),
            Err(error) => {
                eprintln!("Could not read system tray state: {error}");
                Vec::new()
            }
        }
    }

    pub(crate) fn activate(&self, name: String) {
        if self.commands.send(TrayCommand::Activate(name)).is_err() {
            eprintln!("Could not send system tray activation: tray service is stopped");
        }
    }

    pub(crate) fn context_menu(&self, name: String) {
        if self.commands.send(TrayCommand::ContextMenu(name)).is_err() {
            eprintln!("Could not open system tray menu: tray service is stopped");
        }
    }

    pub(crate) fn menu_item_clicked(&self, name: String, menu_path: String, menu_id: i32) {
        if self
            .commands
            .send(TrayCommand::MenuItemClicked {
                name,
                menu_path,
                menu_id,
            })
            .is_err()
        {
            eprintln!("Could not activate system tray menu item: tray service is stopped");
        }
    }

    pub(crate) async fn run(self, mut commands: UnboundedReceiver<TrayCommand>) {
        let connection = match Connection::session().await {
            Ok(connection) => connection,
            Err(error) => {
                eprintln!("Could not connect to the session bus for system tray: {error}");
                return;
            }
        };
        let watcher_items = Arc::new(Mutex::new(Vec::new()));
        let watcher = StatusNotifierWatcher {
            items: watcher_items.clone(),
        };
        if let Err(error) = connection.object_server().at(WATCHER_PATH, watcher).await {
            eprintln!("Could not register the system tray watcher: {error}");
            return;
        }
        let dbus = match DBusProxy::new(&connection).await {
            Ok(proxy) => proxy,
            Err(error) => {
                eprintln!("Could not initialize the session bus proxy: {error}");
                return;
            }
        };
        match dbus
            .request_name(WATCHER_NAME, RequestNameFlags::AllowReplacement.into())
            .await
        {
            Ok(RequestNameReply::PrimaryOwner | RequestNameReply::AlreadyOwner) => {}
            Ok(reply) => {
                eprintln!("Could not own the system tray watcher bus name: {reply:?}");
                return;
            }
            Err(error) => {
                eprintln!("Could not claim the system tray watcher bus name: {error}");
                return;
            }
        }
        match zbus::object_server::SignalEmitter::new(&connection, WATCHER_PATH) {
            Ok(emitter) => {
                if let Err(error) =
                    StatusNotifierWatcher::status_notifier_host_registered(&emitter).await
                {
                    eprintln!("Could not announce the system tray host: {error}");
                }
            }
            Err(error) => eprintln!("Could not create system tray host signal: {error}"),
        }

        if let Err(error) = discover_existing_items(&dbus, &watcher_items).await {
            eprintln!("Could not discover existing system tray items: {error}");
        }

        let mut refresh = tokio::time::interval(Duration::from_secs(2));
        loop {
            tokio::select! {
                _ = refresh.tick() => {
                    if let Err(error) = self.refresh_items(&connection, &watcher_items).await {
                        eprintln!("Could not refresh system tray items: {error}");
                    }
                }
                Some(command) = commands.recv() => {
                    if let Err(error) = execute_command(&connection, command).await {
                        eprintln!("System tray action failed: {error}");
                    }
                }
                else => return,
            }
        }
    }

    async fn refresh_items(
        &self,
        connection: &Connection,
        watcher_items: &Arc<Mutex<Vec<String>>>,
    ) -> zbus::Result<()> {
        let names = match watcher_items.lock() {
            Ok(names) => names.clone(),
            Err(error) => {
                eprintln!("Could not read registered system tray items: {error}");
                return Ok(());
            }
        };
        let mut items = Vec::with_capacity(names.len());
        let mut active_names = Vec::with_capacity(names.len());
        for name in names {
            match item_info(connection, &name).await {
                Ok(item) => {
                    active_names.push(name);
                    items.push(item);
                }
                Err(error) => eprintln!("Could not read system tray item {name}: {error}"),
            }
        }
        let removed_names = match watcher_items.lock() {
            Ok(mut names) => {
                let removed = names
                    .iter()
                    .filter(|name| !active_names.contains(name))
                    .cloned()
                    .collect::<Vec<_>>();
                names.retain(|name| active_names.contains(name));
                removed
            }
            Err(error) => {
                eprintln!("Could not prune system tray items: {error}");
                Vec::new()
            }
        };
        if !removed_names.is_empty() {
            match zbus::object_server::SignalEmitter::new(connection, WATCHER_PATH) {
                Ok(emitter) => {
                    for name in removed_names {
                        if let Err(error) =
                            StatusNotifierWatcher::status_notifier_item_unregistered(
                                &emitter, &name,
                            )
                            .await
                        {
                            eprintln!("Could not signal tray item removal {name}: {error}");
                        }
                    }
                }
                Err(error) => eprintln!("Could not create tray removal signal: {error}"),
            }
        }
        match self.items.lock() {
            Ok(mut current) => *current = items,
            Err(error) => eprintln!("Could not update system tray state: {error}"),
        }
        Ok(())
    }
}

#[derive(Clone)]
struct StatusNotifierWatcher {
    items: Arc<Mutex<Vec<String>>>,
}

#[zbus::interface(name = "org.kde.StatusNotifierWatcher")]
impl StatusNotifierWatcher {
    async fn register_status_notifier_item(
        &self,
        service: &str,
        #[zbus(header)] header: Header<'_>,
        #[zbus(signal_emitter)] emitter: zbus::object_server::SignalEmitter<'_>,
    ) {
        let Some(sender) = header.sender().map(|sender| sender.to_string()) else {
            eprintln!("StatusNotifierItem registration did not include a sender");
            return;
        };
        let item_name = if service.starts_with('/') {
            format!("{sender}{service}")
        } else {
            service.to_owned()
        };
        let registered = match self.items.lock() {
            Ok(mut items) if !items.contains(&item_name) => {
                items.push(item_name.clone());
                true
            }
            Ok(_) => false,
            Err(error) => {
                eprintln!("Could not register system tray item: {error}");
                return;
            }
        };
        if registered
            && let Err(error) = Self::status_notifier_item_registered(&emitter, &item_name).await
        {
            eprintln!("Could not signal system tray item registration: {error}");
        }
    }

    fn register_status_notifier_host(&self, _service: &str) {}

    #[zbus(property)]
    fn registered_status_notifier_items(&self) -> Vec<String> {
        match self.items.lock() {
            Ok(items) => items.clone(),
            Err(error) => {
                eprintln!("Could not list registered system tray items: {error}");
                Vec::new()
            }
        }
    }

    #[zbus(property)]
    fn is_status_notifier_host_registered(&self) -> bool {
        true
    }

    #[zbus(property)]
    fn protocol_version(&self) -> i32 {
        0
    }

    #[zbus(signal)]
    async fn status_notifier_item_registered(
        emitter: &zbus::object_server::SignalEmitter<'_>,
        service: &str,
    ) -> zbus::Result<()>;

    #[zbus(signal)]
    async fn status_notifier_item_unregistered(
        emitter: &zbus::object_server::SignalEmitter<'_>,
        service: &str,
    ) -> zbus::Result<()>;

    #[zbus(signal)]
    async fn status_notifier_host_registered(
        emitter: &zbus::object_server::SignalEmitter<'_>,
    ) -> zbus::Result<()>;

    #[zbus(signal)]
    async fn status_notifier_host_unregistered(
        emitter: &zbus::object_server::SignalEmitter<'_>,
    ) -> zbus::Result<()>;
}

async fn discover_existing_items(
    dbus: &DBusProxy<'_>,
    items: &Arc<Mutex<Vec<String>>>,
) -> zbus::Result<()> {
    for name in dbus.list_names().await? {
        if name.as_str().contains("StatusNotifierItem") {
            match dbus.get_name_owner(name.clone().into()).await {
                Ok(owner) => match items.lock() {
                    Ok(mut items) => {
                        let path_name = format!("{owner}/StatusNotifierItem");
                        if !items.contains(&path_name) {
                            items.push(path_name);
                        }
                    }
                    Err(error) => eprintln!("Could not track existing tray item: {error}"),
                },
                Err(error) => eprintln!("Could not find owner for {name}: {error}"),
            }
        }
    }
    Ok(())
}

async fn item_info(connection: &Connection, name: &str) -> zbus::Result<TrayItem> {
    let (destination, path) = split_item_name(name);
    let proxy = StatusNotifierItemProxy::builder(connection)
        .destination(destination)?
        .path(path)?
        .build()
        .await?;
    let title = match proxy.title().await {
        Ok(title) => title,
        Err(error) => {
            eprintln!("Could not read the title for system tray item {name}: {error}");
            String::new()
        }
    };
    let id = match proxy.id().await {
        Ok(id) => id,
        Err(error) => {
            eprintln!("Could not read the id for system tray item {name}: {error}");
            String::new()
        }
    };
    let pixmaps = match proxy.icon_pixmap().await {
        Ok(pixmaps) => pixmaps,
        Err(error) => {
            eprintln!("Could not read the icon pixmap for system tray item {name}: {error}");
            Vec::new()
        }
    };
    let icon = pixmaps
        .into_iter()
        .filter(|pixmap| {
            pixmap.width > 0
                && pixmap.height > 0
                && pixmap.width <= 512
                && pixmap.height <= 512
                && pixmap.bytes.len() == pixmap.width as usize * pixmap.height as usize * 4
        })
        .max_by_key(|pixmap| (pixmap.width, pixmap.height))
        .map(|mut pixmap| {
            for pixel in pixmap.bytes.as_chunks_mut::<4>().0 {
                pixel.rotate_left(1);
            }
            TrayIcon::Pixmap {
                width: pixmap.width as u32,
                height: pixmap.height as u32,
                data: Arc::new(pixmap.bytes),
            }
        });
    let icon = if icon.is_some() {
        icon
    } else {
        match proxy.icon_name().await {
            Ok(icon_name) if !icon_name.is_empty() => Some(TrayIcon::Name(icon_name)),
            Ok(_) => None,
            Err(error) => {
                eprintln!("Could not read the icon name for system tray item {name}: {error}");
                None
            }
        }
    };
    let menu_path = match proxy.menu().await {
        Ok(path) => path.to_string(),
        Err(error) => {
            eprintln!("Could not read the menu path for system tray item {name}: {error}");
            String::new()
        }
    };
    let menu = if !menu_path.is_empty() && menu_path != "/" {
        match dbus_menu_layout(connection, destination, &menu_path).await {
            Ok(layout) => menu_entries(layout, 0),
            Err(error) => {
                eprintln!("Could not read the menu for system tray item {name}: {error}");
                Vec::new()
            }
        }
    } else {
        Vec::new()
    };
    Ok(TrayItem {
        name: name.to_owned(),
        title: if title.is_empty() {
            if id.is_empty() {
                name.rsplit('/').next().unwrap_or(name).to_owned()
            } else {
                id
            }
        } else {
            title
        },
        icon,
        menu,
        menu_path,
    })
}

async fn execute_command(connection: &Connection, command: TrayCommand) -> zbus::Result<()> {
    match command {
        TrayCommand::MenuItemClicked {
            name,
            menu_path,
            menu_id,
        } => {
            let (destination, _) = split_item_name(&name);
            let proxy = DBusMenuProxy::builder(connection)
                .destination(destination)?
                .path(menu_path)?
                .build()
                .await?;
            let data = zbus::zvariant::Value::I32(0).try_to_owned()?;
            proxy.event(menu_id, "clicked", &data, 0).await
        }
        TrayCommand::Activate(name) => call_item(connection, &name, false).await,
        TrayCommand::ContextMenu(name) => call_item(connection, &name, true).await,
    }
}

async fn call_item(connection: &Connection, name: &str, context_menu: bool) -> zbus::Result<()> {
    let (destination, path) = split_item_name(name);
    let proxy = StatusNotifierItemProxy::builder(connection)
        .destination(destination)?
        .path(path)?
        .build()
        .await?;
    if context_menu {
        proxy.context_menu(0, 0).await
    } else {
        proxy.activate(0, 0).await
    }
}

async fn dbus_menu_layout(
    connection: &Connection,
    destination: &str,
    path: &str,
) -> zbus::Result<MenuLayout> {
    const MENU_PROPERTIES: &[&str] = &["label", "enabled", "visible"];
    let proxy = DBusMenuProxy::builder(connection)
        .destination(destination)?
        .path(path)?
        .build()
        .await?;
    let _ = proxy.about_to_show(0).await?;
    let (_, layout) = proxy.get_layout(0, -1, MENU_PROPERTIES).await?;
    Ok(layout)
}

fn menu_entries(layout: MenuLayout, depth: usize) -> Vec<TrayMenuEntry> {
    if depth >= 5 {
        return Vec::new();
    }
    let MenuLayout(_, _, entries) = layout;
    entries
        .into_iter()
        .filter(|item| item.1.visible.unwrap_or(true))
        .map(|MenuLayout(id, properties, children)| TrayMenuEntry {
            id,
            label: properties.label.unwrap_or_default(),
            enabled: properties.enabled.unwrap_or(true),
            children: menu_entries(
                MenuLayout(0, MenuLayoutProps::default(), children),
                depth + 1,
            ),
        })
        .collect()
}

fn split_item_name(name: &str) -> (&str, &str) {
    match name.find('/') {
        Some(index) => (&name[..index], &name[index..]),
        None => (name, "/StatusNotifierItem"),
    }
}

#[derive(Clone, Debug, zbus::zvariant::Value)]
struct IconPixmap {
    width: i32,
    height: i32,
    bytes: Vec<u8>,
}

#[derive(Clone, Debug, PartialEq, Type)]
#[zvariant(signature = "(ia{sv}av)")]
struct MenuLayout(i32, MenuLayoutProps, Vec<MenuLayout>);

impl<'a> Deserialize<'a> for MenuLayout {
    fn deserialize<D: serde::Deserializer<'a>>(deserializer: D) -> Result<Self, D::Error> {
        let (id, properties, children) =
            <(i32, MenuLayoutProps, Vec<(zbus::zvariant::Signature, Self)>)>::deserialize(
                deserializer,
            )?;
        Ok(Self(
            id,
            properties,
            children.into_iter().map(|(_, item)| item).collect(),
        ))
    }
}

#[derive(Clone, Debug, Default, PartialEq, Type, zbus::zvariant::DeserializeDict)]
#[zvariant(signature = "dict")]
struct MenuLayoutProps {
    #[zvariant(rename = "label")]
    label: Option<String>,
    #[zvariant(rename = "enabled")]
    enabled: Option<bool>,
    #[zvariant(rename = "visible")]
    visible: Option<bool>,
}

#[proxy(interface = "org.kde.StatusNotifierItem")]
trait StatusNotifierItem {
    #[zbus(property)]
    fn title(&self) -> zbus::Result<String>;

    #[zbus(property)]
    fn id(&self) -> zbus::Result<String>;

    #[zbus(property)]
    fn icon_name(&self) -> zbus::Result<String>;

    #[zbus(property)]
    fn icon_pixmap(&self) -> zbus::Result<Vec<IconPixmap>>;

    #[zbus(property)]
    fn menu(&self) -> zbus::Result<zbus::zvariant::OwnedObjectPath>;

    fn activate(&self, x: i32, y: i32) -> zbus::Result<()>;

    fn context_menu(&self, x: i32, y: i32) -> zbus::Result<()>;
}

#[proxy(interface = "com.canonical.dbusmenu")]
trait DBusMenu {
    fn get_layout(
        &self,
        parent_id: i32,
        recursion_depth: i32,
        property_names: &[&str],
    ) -> zbus::Result<(u32, MenuLayout)>;

    fn event(&self, id: i32, event_id: &str, data: &OwnedValue, timestamp: u32)
    -> zbus::Result<()>;

    fn about_to_show(&self, id: i32) -> zbus::Result<bool>;
}

#[cfg(test)]
mod tests {
    use super::{MenuLayout, MenuLayoutProps, menu_entries, split_item_name};

    #[test]
    fn item_address_uses_protocol_default_path_when_omitted() {
        assert_eq!(split_item_name(":1.42"), (":1.42", "/StatusNotifierItem"));
    }

    #[test]
    fn item_address_preserves_explicit_object_path() {
        assert_eq!(
            split_item_name(":1.42/org/example/Tray"),
            (":1.42", "/org/example/Tray")
        );
    }

    #[test]
    fn menu_layout_preserves_enabled_state_and_nested_entries() {
        let child = MenuLayout(
            2,
            MenuLayoutProps {
                label: Some("Preferences".into()),
                enabled: Some(true),
                visible: Some(true),
            },
            Vec::new(),
        );
        let layout = MenuLayout(
            0,
            MenuLayoutProps::default(),
            vec![MenuLayout(
                1,
                MenuLayoutProps {
                    label: Some("Settings".into()),
                    enabled: Some(false),
                    visible: Some(true),
                },
                vec![child],
            )],
        );

        let entries = menu_entries(layout, 0);
        assert_eq!(entries.len(), 1);
        assert_eq!(entries[0].label, "Settings");
        assert!(!entries[0].enabled);
        assert_eq!(entries[0].children[0].label, "Preferences");
    }

    #[test]
    fn menu_layout_omits_invisible_entries() {
        let layout = MenuLayout(
            0,
            MenuLayoutProps::default(),
            vec![MenuLayout(
                1,
                MenuLayoutProps {
                    label: Some("Hidden".into()),
                    enabled: None,
                    visible: Some(false),
                },
                Vec::new(),
            )],
        );

        assert!(menu_entries(layout, 0).is_empty());
    }
}
