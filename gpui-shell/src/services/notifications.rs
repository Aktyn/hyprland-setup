use std::{
    collections::HashMap,
    sync::{
        Arc, Mutex,
        atomic::{AtomicU32, Ordering},
    },
    time::{Duration, Instant, SystemTime},
};

use tokio::sync::mpsc::{self, UnboundedReceiver, UnboundedSender};
use zbus::{
    Connection,
    fdo::{DBusProxy, RequestNameFlags, RequestNameReply},
    names::WellKnownName,
    zvariant::OwnedValue,
};

const NOTIFICATIONS_NAME: WellKnownName =
    WellKnownName::from_static_str_unchecked("org.freedesktop.Notifications");
const NOTIFICATIONS_PATH: &str = "/org/freedesktop/Notifications";
const HISTORY_LIMIT: usize = 64;

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct Notification {
    pub(crate) id: u32,
    pub(crate) app_name: String,
    pub(crate) summary: String,
    pub(crate) body: String,
    pub(crate) icon: String,
    pub(crate) urgency: u8,
    pub(crate) actions: Vec<(String, String)>,
    pub(crate) created_at: SystemTime,
    pub(crate) unread: bool,
    transient: bool,
    active: bool,
    expires_at: Option<Instant>,
}

impl Notification {
    pub(crate) fn toast_visible(&self) -> bool {
        self.active
            && self.unread
            && self
                .expires_at
                .is_none_or(|expires_at| expires_at > Instant::now())
    }
}

#[derive(Clone)]
pub(crate) struct NotificationService {
    items: Arc<Mutex<Vec<Notification>>>,
    commands: UnboundedSender<NotificationCommand>,
    next_id: Arc<AtomicU32>,
    default_timeout_ms: Arc<AtomicU32>,
}

pub(crate) enum NotificationCommand {
    Dismiss(Vec<u32>),
    InvokeAction(u32, String),
}

impl NotificationService {
    pub(crate) fn new() -> (Self, UnboundedReceiver<NotificationCommand>) {
        let (commands, receiver) = mpsc::unbounded_channel();
        (
            Self {
                items: Arc::new(Mutex::new(Vec::new())),
                commands,
                next_id: Arc::new(AtomicU32::new(0)),
                default_timeout_ms: Arc::new(AtomicU32::new(8000)),
            },
            receiver,
        )
    }

    pub(crate) fn snapshot(&self) -> Vec<Notification> {
        match self.items.lock() {
            Ok(items) => items.clone(),
            Err(error) => {
                eprintln!("Could not read notification history: {error}");
                Vec::new()
            }
        }
    }

    pub(crate) fn set_default_timeout(&self, timeout_ms: u64) {
        self.default_timeout_ms
            .store(timeout_ms.clamp(1000, 60_000) as u32, Ordering::Relaxed);
    }

    pub(crate) fn acknowledge_all(&self) {
        match self.items.lock() {
            Ok(mut items) => {
                let transient_ids = items
                    .iter()
                    .filter(|item| item.transient && item.active)
                    .map(|item| item.id)
                    .collect::<Vec<_>>();
                if !transient_ids.is_empty()
                    && self
                        .commands
                        .send(NotificationCommand::Dismiss(transient_ids))
                        .is_err()
                {
                    eprintln!(
                        "Could not acknowledge notifications: notification service is stopped"
                    );
                    return;
                }
                items.retain_mut(|item| {
                    if item.transient {
                        false
                    } else {
                        item.unread = false;
                        true
                    }
                });
            }
            Err(error) => eprintln!("Could not acknowledge notifications: {error}"),
        }
    }

    pub(crate) fn dismiss(&self, id: u32) {
        match self.items.lock() {
            Ok(mut items) => {
                let active = items.iter().any(|item| item.id == id && item.active);
                if active
                    && self
                        .commands
                        .send(NotificationCommand::Dismiss(vec![id]))
                        .is_err()
                {
                    eprintln!("Could not dismiss notification: notification service is stopped");
                    return;
                }
                items.retain(|item| item.id != id);
            }
            Err(error) => eprintln!("Could not dismiss notification: {error}"),
        }
    }

    pub(crate) fn dismiss_all(&self) {
        match self.items.lock() {
            Ok(mut items) => {
                let active_ids = items
                    .iter()
                    .filter(|item| item.active)
                    .map(|item| item.id)
                    .collect();
                if self
                    .commands
                    .send(NotificationCommand::Dismiss(active_ids))
                    .is_err()
                {
                    eprintln!("Could not dismiss notifications: notification service is stopped");
                    return;
                }
                items.clear();
            }
            Err(error) => eprintln!("Could not clear notification history: {error}"),
        }
    }

    pub(crate) fn invoke_action(&self, id: u32, key: String) {
        if self
            .commands
            .send(NotificationCommand::InvokeAction(id, key))
            .is_err()
        {
            eprintln!("Could not invoke notification action: notification service is stopped");
        }
    }

    pub(crate) async fn run(self, mut commands: UnboundedReceiver<NotificationCommand>) {
        let connection = match Connection::session().await {
            Ok(connection) => connection,
            Err(error) => {
                eprintln!("Could not connect to the session bus for notifications: {error}");
                return;
            }
        };
        let server = NotificationServer {
            items: self.items.clone(),
            next_id: self.next_id.clone(),
            default_timeout_ms: self.default_timeout_ms.clone(),
        };
        if let Err(error) = connection
            .object_server()
            .at(NOTIFICATIONS_PATH, server)
            .await
        {
            eprintln!("Could not register the notification server: {error}");
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
            .request_name(
                NOTIFICATIONS_NAME,
                RequestNameFlags::AllowReplacement.into(),
            )
            .await
        {
            Ok(RequestNameReply::PrimaryOwner | RequestNameReply::AlreadyOwner) => {}
            Ok(reply) => {
                eprintln!("Could not own the notification server bus name: {reply:?}");
                return;
            }
            Err(error) => {
                eprintln!("Could not claim the notification server bus name: {error}");
                return;
            }
        }

        let mut expiration = tokio::time::interval(Duration::from_secs(1));
        loop {
            tokio::select! {
                _ = expiration.tick() => {
                    if let Err(error) = expire_notifications(&connection, &self.items).await {
                        eprintln!("Could not expire notifications: {error}");
                    }
                }
                Some(command) = commands.recv() => {
                    if let Err(error) = handle_command(&connection, &self.items, command).await {
                        eprintln!("Notification action failed: {error}");
                    }
                }
                else => return,
            }
        }
    }
}

struct NotificationServer {
    items: Arc<Mutex<Vec<Notification>>>,
    next_id: Arc<AtomicU32>,
    default_timeout_ms: Arc<AtomicU32>,
}

#[zbus::interface(name = "org.freedesktop.Notifications")]
impl NotificationServer {
    fn notify(
        &self,
        app_name: &str,
        replaces_id: u32,
        app_icon: &str,
        summary: &str,
        body: &str,
        actions: Vec<String>,
        hints: HashMap<String, OwnedValue>,
        expire_timeout: i32,
    ) -> zbus::fdo::Result<u32> {
        let urgency = hints
            .get("urgency")
            .and_then(|value| u8::try_from(value.clone()).ok())
            .unwrap_or(1)
            .min(2);
        let icon = hints
            .get("image-path")
            .or_else(|| hints.get("image_path"))
            .and_then(|value| String::try_from(value.clone()).ok())
            .filter(|value| !value.is_empty())
            .unwrap_or_else(|| app_icon.to_owned());
        let transient = hints
            .get("transient")
            .and_then(|value| bool::try_from(value.clone()).ok())
            .unwrap_or(false);
        let timeout = if expire_timeout > 0 {
            expire_timeout as u32
        } else {
            self.default_timeout_ms.load(Ordering::Relaxed)
        };
        let expires_at =
            (urgency != 2).then(|| Instant::now() + Duration::from_millis(timeout.into()));
        let action_pairs = actions
            .chunks_exact(2)
            .map(|pair| (pair[0].clone(), pair[1].clone()))
            .collect();
        let mut items = self
            .items
            .lock()
            .map_err(|error| zbus::fdo::Error::Failed(error.to_string()))?;
        let id = if replaces_id != 0 && items.iter().any(|item| item.id == replaces_id) {
            replaces_id
        } else {
            loop {
                let id = self.next_id.fetch_add(1, Ordering::Relaxed).wrapping_add(1);
                if id != 0 && items.iter().all(|item| item.id != id) {
                    break id;
                }
            }
        };
        let notification = Notification {
            id,
            app_name: app_name.to_owned(),
            summary: summary.to_owned(),
            body: body.to_owned(),
            icon,
            urgency,
            actions: action_pairs,
            created_at: SystemTime::now(),
            unread: true,
            transient,
            active: true,
            expires_at,
        };
        items.retain(|item| item.id != id);
        items.insert(0, notification);
        items.truncate(HISTORY_LIMIT);
        Ok(id)
    }

    async fn close_notification(
        &self,
        id: u32,
        #[zbus(signal_emitter)] emitter: zbus::object_server::SignalEmitter<'_>,
    ) -> zbus::fdo::Result<()> {
        if remove_active_notification(&self.items, id).map_err(zbus::fdo::Error::Failed)? {
            Self::notification_closed(&emitter, id, 3)
                .await
                .map_err(|error| zbus::fdo::Error::Failed(error.to_string()))?;
        }
        Ok(())
    }

    fn get_capabilities(&self) -> Vec<String> {
        vec!["actions".into(), "body".into()]
    }

    fn get_server_information(&self) -> (String, String, String, String) {
        (
            "Aktyn Shell".into(),
            "Aktyn".into(),
            env!("CARGO_PKG_VERSION").into(),
            "1.2".into(),
        )
    }

    #[zbus(signal)]
    async fn notification_closed(
        emitter: &zbus::object_server::SignalEmitter<'_>,
        id: u32,
        reason: u32,
    ) -> zbus::Result<()>;

    #[zbus(signal)]
    async fn action_invoked(
        emitter: &zbus::object_server::SignalEmitter<'_>,
        id: u32,
        action_key: &str,
    ) -> zbus::Result<()>;
}

async fn handle_command(
    connection: &Connection,
    items: &Arc<Mutex<Vec<Notification>>>,
    command: NotificationCommand,
) -> zbus::Result<()> {
    match command {
        NotificationCommand::Dismiss(ids) => {
            if ids.is_empty() {
                return Ok(());
            }
            let emitter = zbus::object_server::SignalEmitter::new(connection, NOTIFICATIONS_PATH)?;
            for id in ids {
                remove_notification(items, id).map_err(zbus::Error::Failure)?;
                NotificationServer::notification_closed(&emitter, id, 2).await?;
            }
        }
        NotificationCommand::InvokeAction(id, key) => {
            let exists = items
                .lock()
                .map_err(|error| zbus::Error::Failure(error.to_string()))?
                .iter()
                .any(|item| {
                    item.id == id
                        && item.active
                        && item
                            .actions
                            .iter()
                            .any(|(action_key, _)| action_key == &key)
                });
            if !exists {
                return Ok(());
            }
            let emitter = zbus::object_server::SignalEmitter::new(connection, NOTIFICATIONS_PATH)?;
            NotificationServer::action_invoked(&emitter, id, &key).await?;
        }
    }
    Ok(())
}

async fn expire_notifications(
    connection: &Connection,
    items: &Arc<Mutex<Vec<Notification>>>,
) -> zbus::Result<()> {
    let expired = match items.lock() {
        Ok(mut items) => {
            let now = Instant::now();
            let mut expired = Vec::new();
            items.retain_mut(|item| {
                if item.expires_at.is_some_and(|deadline| deadline <= now) {
                    expired.push(item.id);
                    if item.transient {
                        false
                    } else {
                        item.unread = false;
                        item.active = false;
                        item.expires_at = None;
                        true
                    }
                } else {
                    true
                }
            });
            expired
        }
        Err(error) => {
            eprintln!("Could not check notification expiration: {error}");
            return Ok(());
        }
    };
    if expired.is_empty() {
        return Ok(());
    }
    let emitter = zbus::object_server::SignalEmitter::new(connection, NOTIFICATIONS_PATH)?;
    for id in expired {
        NotificationServer::notification_closed(&emitter, id, 1).await?;
    }
    Ok(())
}

fn remove_notification(items: &Arc<Mutex<Vec<Notification>>>, id: u32) -> Result<bool, String> {
    let mut items = items.lock().map_err(|error| error.to_string())?;
    let length = items.len();
    items.retain(|item| item.id != id);
    Ok(items.len() != length)
}

fn remove_active_notification(
    items: &Arc<Mutex<Vec<Notification>>>,
    id: u32,
) -> Result<bool, String> {
    let mut items = items.lock().map_err(|error| error.to_string())?;
    let Some(index) = items.iter().position(|item| item.id == id && item.active) else {
        return Ok(false);
    };
    items.remove(index);
    Ok(true)
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio::time::sleep;

    fn server() -> NotificationServer {
        NotificationServer {
            items: Arc::new(Mutex::new(Vec::new())),
            next_id: Arc::new(AtomicU32::new(0)),
            default_timeout_ms: Arc::new(AtomicU32::new(8000)),
        }
    }

    #[test]
    fn notify_tracks_notification_content_and_actions() {
        let server = server();
        let id = server
            .notify(
                "Mail",
                0,
                "",
                "New message",
                "Hello",
                vec!["open".into(), "Open".into()],
                HashMap::new(),
                5000,
            )
            .unwrap();
        let items = server.items.lock().unwrap();
        assert_eq!(items.len(), 1);
        assert_eq!(items[0].id, id);
        assert_eq!(items[0].summary, "New message");
        assert_eq!(items[0].body, "Hello");
        assert_eq!(items[0].actions, [("open".into(), "Open".into())]);
        assert!(items[0].unread);
        assert!(items[0].active);
        assert!(items[0].expires_at.is_some());
    }

    #[test]
    fn notify_replaces_existing_entry_by_id() {
        let server = server();
        let id = server
            .notify("Mail", 0, "", "First", "", Vec::new(), HashMap::new(), 5000)
            .unwrap();
        let replacement = server
            .notify(
                "Mail",
                id,
                "",
                "Updated",
                "",
                Vec::new(),
                HashMap::new(),
                5000,
            )
            .unwrap();
        let items = server.items.lock().unwrap();
        assert_eq!(replacement, id);
        assert_eq!(items.len(), 1);
        assert_eq!(items[0].summary, "Updated");
    }

    #[test]
    fn critical_notifications_do_not_expire() {
        let server = server();
        let hints = HashMap::from([(
            "urgency".to_owned(),
            zbus::zvariant::Value::U8(2).try_to_owned().unwrap(),
        )]);
        server
            .notify("Shell", 0, "", "Critical", "", Vec::new(), hints, 1000)
            .unwrap();
        let items = server.items.lock().unwrap();
        assert_eq!(items[0].urgency, 2);
        assert!(items[0].expires_at.is_none());
    }

    #[test]
    fn acknowledging_notifications_removes_transient_entries() {
        let (service, mut commands) = NotificationService::new();
        let server = NotificationServer {
            items: service.items.clone(),
            next_id: service.next_id.clone(),
            default_timeout_ms: service.default_timeout_ms.clone(),
        };
        let transient_hints = HashMap::from([(
            "transient".to_owned(),
            zbus::zvariant::Value::Bool(true).try_to_owned().unwrap(),
        )]);
        let transient_id = server
            .notify(
                "Shell",
                0,
                "",
                "Transient",
                "",
                Vec::new(),
                transient_hints,
                5000,
            )
            .unwrap();
        server
            .notify(
                "Mail",
                0,
                "",
                "Persistent",
                "",
                Vec::new(),
                HashMap::new(),
                5000,
            )
            .unwrap();

        service.acknowledge_all();

        let items = service.snapshot();
        assert_eq!(items.len(), 1);
        assert_eq!(items[0].summary, "Persistent");
        assert!(!items[0].unread);
        assert!(matches!(
            commands.try_recv(),
            Ok(NotificationCommand::Dismiss(ids)) if ids == [transient_id]
        ));
    }

    #[zbus::proxy(interface = "org.freedesktop.Notifications")]
    trait NotificationTestApi {
        fn notify(
            &self,
            app_name: &str,
            replaces_id: u32,
            app_icon: &str,
            summary: &str,
            body: &str,
            actions: Vec<String>,
            hints: HashMap<String, OwnedValue>,
            expire_timeout: i32,
        ) -> zbus::Result<u32>;

        fn close_notification(&self, id: u32) -> zbus::Result<()>;

        fn get_capabilities(&self) -> zbus::Result<Vec<String>>;
    }

    #[tokio::test]
    async fn private_bus_implements_notification_protocol() {
        if std::env::var_os("AKTYN_PRIVATE_DBUS_TEST").is_none() {
            return;
        }
        let (service, receiver) = NotificationService::new();
        let worker = tokio::spawn(service.clone().run(receiver));
        let connection = Connection::session().await.unwrap();
        let bus = DBusProxy::new(&connection).await.unwrap();
        let proxy = NotificationTestApiProxy::builder(&connection)
            .destination(NOTIFICATIONS_NAME)
            .unwrap()
            .path(NOTIFICATIONS_PATH)
            .unwrap()
            .build()
            .await
            .unwrap();
        let mut ready = false;
        for _ in 0..50 {
            let names = bus.list_names().await.unwrap();
            if names
                .iter()
                .any(|name| name.as_str() == NOTIFICATIONS_NAME.as_str())
            {
                ready = true;
                break;
            }
            sleep(Duration::from_millis(20)).await;
        }
        assert!(ready, "notification service did not acquire its bus name");
        assert!(
            proxy
                .get_capabilities()
                .await
                .unwrap()
                .contains(&"actions".to_owned())
        );
        let id = proxy
            .notify(
                "Test",
                0,
                "",
                "Notification test",
                "private session bus",
                Vec::new(),
                HashMap::new(),
                5000,
            )
            .await
            .unwrap();
        assert_eq!(service.snapshot()[0].id, id);
        proxy.close_notification(id).await.unwrap();
        assert!(service.snapshot().is_empty());
        worker.abort();
    }
}
