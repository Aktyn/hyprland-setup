use chrono::Local;
use gpui::{
    Context, DisplayId, Entity, MouseButton, Render, RenderImage, Window, WindowHandle, div, img,
    prelude::*, px, rgb, rgba,
};
use image::{Frame, RgbaImage};
use std::{collections::HashMap, sync::Arc};

use crate::{
    config::ConfigStore,
    model::{PanelKind, Status},
    services::{
        NotificationService, TrayIcon, TrayItem, TrayService, dispatch, find_app_icon, launch_app,
        read_status, run_detached, toggle_bluetooth, toggle_night_light,
    },
    ui::{ShellPanel, ShellTrayMenu, panel_window_options, tray_menu_window_options},
};

use super::theme::{
    error, foreground, muted, on_primary, outline, primary, surface_high, surface_with_opacity,
};
use super::{app_icon_name, bar_icon_button, material_icon};

struct CachedTrayIcon {
    source: Arc<Vec<u8>>,
    desaturation: f32,
    image: Arc<RenderImage>,
}

pub(crate) struct ShellBar {
    config: Entity<ConfigStore>,
    display_id: Option<DisplayId>,
    tray_service: TrayService,
    notification_service: NotificationService,
    pub(crate) tray_items: Vec<TrayItem>,
    tray_icons: HashMap<String, CachedTrayIcon>,
    tray_menu: Option<(String, WindowHandle<ShellTrayMenu>)>,
    pub(crate) status: Status,
    pub(crate) now: chrono::DateTime<Local>,
    pub(crate) panel: Option<WindowHandle<ShellPanel>>,
    pub(crate) panel_kind: Option<PanelKind>,
}

impl ShellBar {
    pub(crate) fn new(
        config: Entity<ConfigStore>,
        display_id: Option<DisplayId>,
        tray_service: TrayService,
        notification_service: NotificationService,
        _: &mut Context<Self>,
    ) -> Self {
        Self {
            config,
            display_id,
            tray_service,
            notification_service,
            tray_items: Vec::new(),
            tray_icons: HashMap::new(),
            tray_menu: None,
            status: read_status(),
            now: Local::now(),
            panel: None,
            panel_kind: None,
        }
    }

    pub(crate) fn toggle_panel(&mut self, kind: PanelKind, cx: &mut Context<Self>) {
        self.close_tray_menu(cx);
        if self.panel_kind == Some(kind) {
            self.close_panel(cx);
            return;
        }
        self.close_panel(cx);
        let parent = cx.entity();
        let config = self.config.clone();
        let notifications = self.notification_service.clone();
        let options = panel_window_options(cx, &config, self.display_id, kind);
        match cx.open_window(options, move |_, cx| {
            cx.new(|cx| ShellPanel::new(kind, parent, config, notifications, cx))
        }) {
            Ok(panel) => {
                self.panel = Some(panel);
                self.panel_kind = Some(kind);
            }
            Err(error) => eprintln!("Could not open {} panel: {error}", kind.title()),
        }
    }

    fn close_panel(&mut self, cx: &mut Context<Self>) {
        self.panel_kind = None;
        if let Some(panel) = self.panel.take() {
            if let Err(error) = panel.update(cx, |_, window, _| window.remove_window()) {
                eprintln!("Could not close shell panel: {error}");
            }
        }
    }

    pub(crate) fn close_tray_menu(&mut self, cx: &mut Context<Self>) {
        if let Some((_, menu)) = self.tray_menu.take()
            && let Err(error) = menu.update(cx, |_, window, _| window.remove_window())
        {
            eprintln!("Could not close the system tray menu: {error}");
        }
    }

    fn open_tray_menu(&mut self, item: TrayItem, cx: &mut Context<Self>) {
        if self
            .tray_menu
            .as_ref()
            .is_some_and(|(name, _)| name == &item.name)
        {
            self.close_tray_menu(cx);
            return;
        }
        self.close_tray_menu(cx);
        let item_name = item.name.clone();
        let parent = cx.entity();
        let service = self.tray_service.clone();
        let config = self.config.clone();
        let options = tray_menu_window_options(cx, &config, self.display_id);
        match cx.open_window(options, move |_, cx| {
            cx.new(|cx| ShellTrayMenu::new(parent, item, service, cx))
        }) {
            Ok(window) => self.tray_menu = Some((item_name, window)),
            Err(error) => eprintln!("Could not open the system tray menu: {error}"),
        }
    }

    fn tray_icon(
        &mut self,
        item: &TrayItem,
        desaturation: f32,
        cx: &mut Context<Self>,
    ) -> Option<Arc<RenderImage>> {
        let Some(TrayIcon::Pixmap {
            width,
            height,
            data,
        }) = &item.icon
        else {
            if let Some(cached) = self.tray_icons.remove(&item.name) {
                cx.drop_image(cached.image, None);
            }
            return None;
        };
        if let Some(cached) = self.tray_icons.get(&item.name)
            && Arc::ptr_eq(&cached.source, data)
            && cached.desaturation == desaturation
        {
            return Some(cached.image.clone());
        }

        let mut pixels = data.as_ref().clone();
        for pixel in pixels.as_chunks_mut::<4>().0 {
            let gray = (pixel[0] as f32 * 0.2126
                + pixel[1] as f32 * 0.7152
                + pixel[2] as f32 * 0.0722) as u8;
            let amount = desaturation.clamp(0.0, 1.0);
            for channel in &mut pixel[..3] {
                *channel = (*channel as f32 * (1.0 - amount) + gray as f32 * amount) as u8;
            }
            pixel.swap(0, 2);
        }
        let Some(buffer) = RgbaImage::from_raw(*width, *height, pixels) else {
            eprintln!("Could not decode tray icon pixmap for {}", item.name);
            return None;
        };
        let image = Arc::new(RenderImage::new(vec![Frame::new(buffer)]));
        if let Some(previous) = self.tray_icons.insert(
            item.name.clone(),
            CachedTrayIcon {
                source: data.clone(),
                desaturation,
                image: image.clone(),
            },
        ) {
            cx.drop_image(previous.image, None);
        }
        Some(image)
    }

    fn discard_stale_tray_icons(&mut self, cx: &mut Context<Self>) {
        let stale = self
            .tray_icons
            .keys()
            .filter(|name| !self.tray_items.iter().any(|item| &item.name == *name))
            .cloned()
            .collect::<Vec<_>>();
        for name in stale {
            if let Some(cached) = self.tray_icons.remove(&name) {
                cx.drop_image(cached.image, None);
            }
        }
    }

    fn render_tray_item(
        &mut self,
        item: &TrayItem,
        desaturation: f32,
        cx: &mut Context<Self>,
    ) -> gpui::Div {
        let image = self.tray_icon(item, desaturation, cx);
        let name = item.name.clone();
        let activate = cx.listener(move |bar, _, _, cx| {
            bar.activate_tray_item(&name, cx);
        });
        let context_name = item.name.clone();
        let context_menu = cx.listener(move |bar, _, _, cx| {
            bar.open_tray_context_menu(&context_name, cx);
        });
        let icon = image
            .map(|image| {
                div()
                    .size(px(20.))
                    .child(img(image).size(px(20.)))
                    .into_any_element()
            })
            .unwrap_or_else(|| {
                let label = if item.title.is_empty() {
                    item.name.rsplit('/').next().unwrap_or(&item.name)
                } else {
                    &item.title
                };
                div()
                    .text_size(px(11.))
                    .text_color(rgb(muted()))
                    .child(label.chars().take(8).collect::<String>())
                    .into_any_element()
            });
        div()
            .w(px(30.))
            .h(px(30.))
            .flex()
            .items_center()
            .justify_center()
            .rounded(px(15.))
            .cursor_pointer()
            .hover(|style| style.bg(rgb(surface_high())))
            .on_mouse_down(MouseButton::Left, activate)
            .on_mouse_down(MouseButton::Right, context_menu)
            .child(icon)
    }

    fn activate_tray_item(&mut self, name: &str, cx: &mut Context<Self>) {
        self.tray_service.activate(name.to_owned());
        cx.notify();
    }

    fn open_tray_context_menu(&mut self, name: &str, cx: &mut Context<Self>) {
        if let Some(item) = self
            .tray_items
            .iter()
            .find(|item| item.name == name && !item.menu.is_empty())
            .cloned()
        {
            self.open_tray_menu(item, cx);
        } else {
            self.tray_service.context_menu(name.to_owned());
        }
        cx.notify();
    }
}

impl Render for ShellBar {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let config = self.config.read(cx).value.clone();
        let bar_height = px(config.bar.height as f32);
        let surface = surface_with_opacity(config.general.panels_transparency);
        let active_workspace = self.status.workspace;
        let occupied_workspaces = self.status.occupied_workspaces.clone();
        let workspace_app_classes = self.status.workspace_app_classes.clone();
        let notifications = self.notification_service.snapshot();
        let notification_count = notifications.len();
        let unread_notifications = notifications
            .iter()
            .filter(|notification| notification.unread)
            .count();
        let show_notifications = notification_count > 0;
        let bluetooth_enabled = self.status.bluetooth_enabled;
        let app_id = self.status.active_window_app_id.clone();
        let active_title = self.status.active_window.clone();
        let all_running_classes: Vec<String> = workspace_app_classes
            .values()
            .flatten()
            .map(|c| c.to_lowercase())
            .collect();

        let pinned_app_elements = config
            .bar
            .pinned_apps
            .iter()
            .map(|app_id| {
                let app_id_str = app_id.clone();
                let is_running = all_running_classes.iter().any(|c| {
                    c == &app_id_str.to_lowercase() || app_id_str.to_lowercase().contains(c)
                });
                let icon_path = find_app_icon(&app_id_str);
                let icon_element: gpui::AnyElement = if let Some(path) = icon_path {
                    img(path).size(px(20.)).into_any_element()
                } else {
                    material_icon(app_icon_name(&app_id_str), 18., muted()).into_any_element()
                };

                let launch_id = app_id_str.clone();
                let unpin_id = app_id_str.clone();
                let config_store = self.config.clone();

                div()
                    .id(format!("pinned-app-{}", app_id_str))
                    .w(px(26.))
                    .h(px(26.))
                    .flex()
                    .flex_col()
                    .items_center()
                    .justify_center()
                    .rounded(px(6.))
                    .cursor_pointer()
                    .hover(|style| style.bg(rgba((primary() << 8) | 0x33)))
                    .child(icon_element)
                    .when(is_running, |el| {
                        el.child(
                            div()
                                .w(px(14.))
                                .h(px(2.))
                                .rounded(px(1.))
                                .bg(rgba((primary() << 8) | 0xaa)),
                        )
                    })
                    .on_mouse_down(MouseButton::Left, move |_, _, _| {
                        launch_app(&launch_id);
                    })
                    .on_mouse_down(MouseButton::Right, move |_, _, cx| {
                        let unpin = unpin_id.clone();
                        config_store.update(cx, |store, cx| {
                            store.value.bar.pinned_apps.retain(|id| id != &unpin);
                            store.save();
                            cx.notify();
                        });
                    })
            })
            .collect::<Vec<_>>();
        let has_pinned_apps = !pinned_app_elements.is_empty();

        let workspace_count = config.workspaces.count.min(i32::MAX as u32) as i32;
        let workspace_buttons = (1..=workspace_count).map(|workspace| {
            let active = Some(workspace) == active_workspace;
            let occupied = occupied_workspaces.contains(&workspace);
            let app_classes = workspace_app_classes
                .get(&workspace)
                .cloned()
                .unwrap_or_default();
            let contents = if app_classes.is_empty() {
                vec![
                    div()
                        .text_size(px(13.))
                        .child(workspace.to_string())
                        .into_any_element(),
                ]
            } else {
                app_classes
                    .iter()
                    .take(8)
                    .map(|class| {
                        material_icon(
                            app_icon_name(class),
                            17.,
                            if active { on_primary() } else { foreground() },
                        )
                        .into_any_element()
                    })
                    .collect::<Vec<_>>()
            };
            let width = if app_classes.is_empty() {
                40.
            } else {
                ((app_classes.len().min(8) as f32 * 21.) + 8.).clamp(40., 176.)
            };
            div()
                .id(format!("workspace-{workspace}"))
                .w(px(width))
                .h(if active { px(32.) } else { px(24.) })
                .flex()
                .items_center()
                .justify_center()
                .rounded(px(8.))
                .border_1()
                .border_color(rgb(if active { primary() } else { outline() }))
                .bg(rgb(if active { primary() } else { surface_high() }))
                .text_color(rgb(if active { on_primary() } else { foreground() }))
                .opacity(if active || occupied { 1. } else { 0.55 })
                .gap(px(2.))
                .children(contents)
                .on_mouse_down(MouseButton::Left, move |_, _, _| {
                    dispatch(&["dispatch", "workspace", &workspace.to_string()]);
                })
        });
        let media = self
            .status
            .media
            .as_deref()
            .map(|title| title.chars().take(22).collect::<String>());
        let battery = self.status.battery.map(|level| {
            let icon_index = ((level as usize * 7) / 100).min(6);
            let icon = if level >= 98 {
                "battery_android_full"
            } else {
                [
                    "battery_android_0",
                    "battery_android_1",
                    "battery_android_2",
                    "battery_android_3",
                    "battery_android_4",
                    "battery_android_5",
                    "battery_android_6",
                ][icon_index]
            };
            div()
                .flex()
                .items_center()
                .gap(px(3.))
                .cursor_pointer()
                .child(material_icon(
                    icon,
                    19.,
                    if level <= 5 { error() } else { muted() },
                ))
                .when(self.status.battery_charging, |row| {
                    row.child(material_icon("bolt", 14., primary()))
                })
                .child(
                    div()
                        .text_size(px(11.))
                        .text_color(rgb(muted()))
                        .child(format!("{level}%")),
                )
                .on_mouse_down(
                    MouseButton::Left,
                    cx.listener(|this, _, _, cx| this.toggle_panel(PanelKind::Settings, cx)),
                )
        });
        let download = self
            .status
            .download_bps
            .filter(|rate| *rate > 500 * 1024)
            .map(|rate| network_indicator("south", rate));
        let upload = self
            .status
            .upload_bps
            .filter(|rate| *rate > 50 * 1024)
            .map(|rate| network_indicator("north", rate));
        let cpu = self
            .status
            .cpu
            .map(|value| resource_indicator("speed", value));
        let memory = self
            .status
            .memory
            .map(|value| resource_indicator("memory", value));
        let swap = self
            .status
            .swap
            .filter(|value| *value > 0)
            .map(|value| resource_indicator("swap_horiz", value));
        let volume = self.status.volume.map(|level| {
            let shown_level = if self.status.muted { 0 } else { level };
            div()
                .flex()
                .items_center()
                .gap(px(6.))
                .cursor_pointer()
                .child(material_icon(
                    if self.status.muted {
                        "volume_off"
                    } else {
                        "volume_up"
                    },
                    18.,
                    muted(),
                ))
                .child(
                    div()
                        .w(px(58.))
                        .h(px(4.))
                        .rounded(px(2.))
                        .bg(rgb(outline()))
                        .child(
                            div()
                                .w(px(58. * shown_level as f32 / 100.))
                                .h(px(4.))
                                .rounded(px(2.))
                                .bg(rgb(primary())),
                        ),
                )
                .on_mouse_down(
                    MouseButton::Left,
                    cx.listener(|this, _, _, cx| this.toggle_panel(PanelKind::Audio, cx)),
                )
        });
        let resources = div()
            .flex()
            .items_center()
            .gap(px(8.))
            .children(cpu)
            .children(memory)
            .children(swap)
            .cursor_pointer()
            .on_mouse_down(MouseButton::Left, |_, _, _| {
                run_detached("gnome-system-monitor", &[])
            });
        let tools = div()
            .flex()
            .items_center()
            .gap(px(4.))
            .child(bar_icon_button("screenshot_region", false).on_mouse_down(
                MouseButton::Left,
                |_, _, _| {
                    run_detached(
                        "hyprshot",
                        &[
                            "--freeze",
                            "--clipboard-only",
                            "--mode",
                            "region",
                            "--silent",
                        ],
                    )
                },
            ))
            .child(
                bar_icon_button("colorize", false).on_mouse_down(MouseButton::Left, |_, _, _| {
                    run_detached("hyprpicker", &["-a"])
                }),
            )
            .child(
                bar_icon_button("sticky_note_2", self.panel_kind == Some(PanelKind::Notes))
                    .on_mouse_down(
                        MouseButton::Left,
                        cx.listener(|this, _, _, cx| this.toggle_panel(PanelKind::Notes, cx)),
                    ),
            )
            .child(
                bar_icon_button(
                    "pending_actions",
                    self.panel_kind == Some(PanelKind::Clipboard),
                )
                .on_mouse_down(
                    MouseButton::Left,
                    cx.listener(|this, _, _, cx| this.toggle_panel(PanelKind::Clipboard, cx)),
                ),
            );
        let tray_items = self.tray_items.clone();
        self.discard_stale_tray_icons(cx);
        let tray_widgets = tray_items
            .iter()
            .map(|item| self.render_tray_item(item, config.bar.desaturate_tray_icons, cx))
            .collect::<Vec<_>>();
        div()
            .w_full()
            .h(bar_height)
            .px(px(4.))
            .flex()
            .items_center()
            .justify_between()
            .gap(px(12.))
            .bg(surface)
            .rounded_tl(px(16.))
            .rounded_tr(px(16.))
            .font_family("Rubik")
            .text_color(rgb(foreground()))
            .child(
                div()
                    .flex_1()
                    .flex()
                    .items_center()
                    .gap(px(8.))
                    .child(
                        div()
                            .w(px(260.))
                            .flex()
                            .flex_col()
                            .gap(px(1.))
                            .child(
                                div()
                                    .truncate()
                                    .text_size(px(10.))
                                    .text_color(rgb(outline()))
                                    .child(app_id),
                            )
                            .child(
                                div()
                                    .truncate()
                                    .text_size(px(12.))
                                    .text_color(rgb(muted()))
                                    .child(active_title),
                            ),
                    )
                    .child(
                        div()
                            .flex()
                            .items_center()
                            .gap(px(4.))
                            .children(pinned_app_elements)
                            .when(has_pinned_apps, |el| {
                                el.child(
                                    div()
                                        .px(px(2.))
                                        .text_size(px(14.))
                                        .text_color(rgb(outline()))
                                        .child("•"),
                                )
                            })
                            .children(workspace_buttons),
                    ),
            )
            .child(
                div()
                    .flex()
                    .items_center()
                    .gap(px(16.))
                    .child(separator())
                    .child(
                        div()
                            .flex()
                            .items_center()
                            .gap(px(6.))
                            .cursor_pointer()
                            .child(material_icon(
                                "menu",
                                22.,
                                if self.panel_kind == Some(PanelKind::Overview) {
                                    primary()
                                } else {
                                    muted()
                                },
                            ))
                            .child(
                                div()
                                    .flex()
                                    .flex_col()
                                    .items_center()
                                    .gap(px(1.))
                                    .child(
                                        div()
                                            .text_size(px(14.))
                                            .text_color(rgb(
                                                if self.panel_kind == Some(PanelKind::Overview) {
                                                    primary()
                                                } else {
                                                    foreground()
                                                },
                                            ))
                                            .child(self.now.format("%H:%M").to_string()),
                                    )
                                    .child(
                                        div()
                                            .text_size(px(10.))
                                            .text_color(rgb(muted()))
                                            .child(self.now.format("%a, %d/%m").to_string()),
                                    ),
                            )
                            .on_mouse_down(
                                MouseButton::Left,
                                cx.listener(|this, _, _, cx| {
                                    this.toggle_panel(PanelKind::Overview, cx)
                                }),
                            ),
                    )
                    .child(separator()),
            )
            .child(
                div()
                    .flex_1()
                    .flex()
                    .items_center()
                    .justify_end()
                    .gap(px(10.))
                    .child(resources)
                    .child(separator())
                    .child(tools)
                    .child(separator())
                    .when_some(volume, |bar, volume| bar.child(volume))
                    .when_some(media, |bar, title| {
                        bar.child(separator()).child(
                            div()
                                .flex()
                                .items_center()
                                .gap(px(5.))
                                .cursor_pointer()
                                .child(material_icon("music_note", 18., primary()))
                                .child(
                                    div()
                                        .max_w(px(160.))
                                        .truncate()
                                        .text_size(px(11.))
                                        .text_color(rgb(muted()))
                                        .child(title),
                                )
                                .on_mouse_down(
                                    MouseButton::Left,
                                    cx.listener(|this, _, _, cx| {
                                        this.toggle_panel(PanelKind::Audio, cx)
                                    }),
                                ),
                        )
                    })
                    .when_some(upload, |bar, rate| bar.child(rate))
                    .when_some(download, |bar, rate| bar.child(rate))
                    .children(tray_widgets)
                    .child(separator())
                    .when_some(battery, |bar, battery| bar.child(battery))
                    .child(
                        bar_icon_button("bedtime", self.status.night_light_enabled)
                            .on_mouse_down(MouseButton::Left, |_, _, _| toggle_night_light()),
                    )
                    .child(
                        bar_icon_button(
                            if self.status.bluetooth_connected {
                                "bluetooth_connected"
                            } else if self.status.bluetooth_enabled {
                                "bluetooth"
                            } else {
                                "bluetooth_disabled"
                            },
                            self.status.bluetooth_enabled,
                        )
                        .on_mouse_down(MouseButton::Left, move |_, _, _| {
                            toggle_bluetooth(!bluetooth_enabled)
                        })
                        .on_mouse_down(MouseButton::Right, |_, _, _| {
                            run_detached("blueman-manager", &[])
                        }),
                    )
                    .when(show_notifications, |bar| {
                        bar.child(
                            bar_icon_button(
                                if unread_notifications > 0 {
                                    "notifications_active"
                                } else {
                                    "notifications"
                                },
                                unread_notifications > 0,
                            )
                            .on_mouse_down(
                                MouseButton::Left,
                                cx.listener(|this, _, _, cx| {
                                    this.toggle_panel(PanelKind::Notifications, cx)
                                }),
                            ),
                        )
                    }),
            )
    }
}

fn separator() -> gpui::Div {
    div().w(px(1.)).h(px(18.)).bg(rgb(outline()))
}

fn resource_indicator(icon: &str, percentage: u8) -> gpui::Div {
    div()
        .flex()
        .items_center()
        .gap(px(3.))
        .child(material_icon(icon, 17., muted()))
        .child(
            div()
                .text_size(px(11.))
                .text_color(rgb(muted()))
                .child(format!("{percentage}%")),
        )
}

fn network_indicator(icon: &str, rate: u64) -> gpui::Div {
    div()
        .flex()
        .items_center()
        .gap(px(3.))
        .child(material_icon(icon, 16., muted()))
        .child(
            div()
                .text_size(px(10.))
                .text_color(rgb(muted()))
                .child(format_rate(rate)),
        )
}

fn format_rate(bytes_per_second: u64) -> String {
    let mut value = bytes_per_second as f64;
    let units = ["B/s", "KB/s", "MB/s", "GB/s"];
    let mut unit = 0;
    while value >= 1024. && unit < units.len() - 1 {
        value /= 1024.;
        unit += 1;
    }
    format!("{value:.0} {}", units[unit])
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::ShellConfig;

    #[test]
    fn capture_shell_components_offscreen_when_requested() {
        let bar_path = std::env::var_os("AKTYN_CAPTURE_BAR");
        let panel_path = std::env::var_os("AKTYN_CAPTURE_PANEL");
        if bar_path.is_none() && panel_path.is_none() {
            return;
        }
        let platform = gpui_platform::current_platform(true);
        let mut app = gpui::HeadlessAppContext::with_platform(
            platform.text_system(),
            Arc::new(()),
            gpui_platform::current_headless_renderer,
        );
        let status = Status {
            active_window_app_id: "firefox".into(),
            active_window: "A carefully staged GPUI visual preview".into(),
            night_light_enabled: true,
            workspace: Some(2),
            occupied_workspaces: vec![1, 2, 4],
            workspace_app_classes: std::collections::HashMap::from([
                (1, vec!["kitty".into()]),
                (2, vec!["firefox".into(), "code".into()]),
                (4, vec!["spotify".into()]),
            ]),
            battery: Some(76),
            battery_charging: true,
            cpu: Some(18),
            memory: Some(54),
            swap: Some(8),
            download_bps: Some(2 * 1024 * 1024),
            upload_bps: Some(128 * 1024),
            volume: Some(42),
            muted: false,
            media: Some("Artist — Track title".into()),
            bluetooth_enabled: true,
            bluetooth_connected: true,
        };
        let now = Local::now();
        let (bar, config, notification_service) = app.update(|cx| {
            let mut shell_config = ShellConfig::default();
            shell_config.bar.pinned_apps = vec!["kitty".into(), "firefox".into(), "steam".into()];
            let wallpaper_candidate = "/home/aktyn/Pictures/Wallpapers/b-347.jpg";
            if std::path::Path::new(wallpaper_candidate).exists() {
                shell_config.wallpaper.path = wallpaper_candidate.into();
                crate::ui::theme::sync_theme_with_wallpaper(Some(wallpaper_candidate));
            }
            let config = cx.new(|_| ConfigStore {
                value: shell_config,
            });
            let (tray_service, _) = TrayService::new();
            let (notification_service, _) = NotificationService::new();
            let bar = cx.new(|_| ShellBar {
                config: config.clone(),
                display_id: None,
                tray_service,
                notification_service: notification_service.clone(),
                tray_items: Vec::new(),
                tray_icons: HashMap::new(),
                tray_menu: None,
                status,
                now,
                panel: None,
                panel_kind: None,
            });
            (bar, config, notification_service)
        });

        if let Some(path) = bar_path {
            let bar_entity = bar.clone();
            let window = app
                .open_window(gpui::size(px(1920.), px(40.)), move |_, _| bar_entity)
                .expect("open headless bar window");
            let image = app
                .capture_screenshot(window.into())
                .expect("render bar to an offscreen image");
            assert!(image.width() >= 1920);
            assert!(image.height() >= 40);
            save_preview(image, path);
        }
        if let Some(path) = panel_path {
            let panel_config = config.clone();
            let panel_parent = bar.clone();
            let panel_notifications = notification_service.clone();
            let window = app
                .open_window(gpui::size(px(820.), px(850.)), move |_, cx| {
                    cx.new(|cx| {
                        ShellPanel::new(
                            PanelKind::Overview,
                            panel_parent,
                            panel_config,
                            panel_notifications,
                            cx,
                        )
                    })
                })
                .expect("open headless overview panel");
            app.advance_clock(std::time::Duration::from_secs(1));
            let image = app
                .capture_screenshot(window.into())
                .expect("render overview panel to an offscreen image");
            assert!(image.width() >= 500);
            assert!(image.height() >= 720);
            save_preview(image, path);
        }
    }

    fn save_preview(image: RgbaImage, path: std::ffi::OsString) {
        let path = std::path::PathBuf::from(path);
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent).expect("create preview directory");
        }
        image.save(&path).expect("save offscreen shell preview");
        println!(
            "Saved {}x{} offscreen shell preview to {}",
            image.width(),
            image.height(),
            path.display()
        );
    }
}
