use std::time::Duration;

use gpui::{WindowHandle, prelude::*};
use gpui_platform::application;

use crate::{
    config::ConfigStore,
    ipc::acquire_instance,
    model::PanelKind,
    services::{
        BatteryAction, BatteryMonitor, NotificationService, TrayService, read_status, run_detached,
        suspend_system,
    },
    ui::{
        ShellDisplayManager, ShellNotificationToast, notification_toast_window_options,
        observe_display_changes,
    },
};

pub(crate) async fn run() {
    let request = match std::env::args().nth(1).as_deref() {
        None => None,
        Some("--help" | "-h") => {
            println!(
                "aktyn-shell [--toggle|--launcher|--clipboard|--cheatsheet|--notifications|--notes|--settings|--audio|--session]"
            );
            return;
        }
        Some("--toggle") => Some(PanelKind::Overview),
        Some("--launcher") => Some(PanelKind::Overview),
        Some("--clipboard") => Some(PanelKind::Clipboard),
        Some("--cheatsheet") => Some(PanelKind::Cheatsheet),
        Some("--notifications") => Some(PanelKind::Notifications),
        Some("--notes") => Some(PanelKind::Notes),
        Some("--settings") => Some(PanelKind::Settings),
        Some("--audio") => Some(PanelKind::Audio),
        Some("--session") => Some(PanelKind::Session),
        Some(other) => {
            eprintln!("Unknown argument: {other}");
            std::process::exit(2);
        }
    };

    let (receiver, socket_guard) = match acquire_instance(request) {
        Ok(Some(instance)) => instance,
        Ok(None) => return,
        Err(error) => {
            eprintln!("Could not start Aktyn shell: {error}");
            std::process::exit(1);
        }
    };
    let initial_request = request;
    let (tray_service, tray_receiver) = TrayService::new();
    let tray_worker = tray_service.clone();
    tokio::spawn(async move {
        tray_worker.run(tray_receiver).await;
    });
    let (notification_service, notification_receiver) = NotificationService::new();
    let notification_worker = notification_service.clone();
    tokio::spawn(async move {
        notification_worker.run(notification_receiver).await;
    });

    let app = application();
    app.run(move |cx| {
        let config = cx.new(|_| ConfigStore::load());
        let config_for_status = config.clone();
        let notifications_for_status = notification_service.clone();
        let display_manager = cx.new(|_| {
            ShellDisplayManager::new(
                config.clone(),
                tray_service.clone(),
                notification_service.clone(),
            )
        });
        let displays = cx.displays();
        let display_ids: Vec<_> = if displays.is_empty() {
            vec![None]
        } else {
            displays.iter().map(|display| Some(display.id())).collect()
        };
        for display_id in display_ids.iter().copied() {
            display_manager.update(cx, |manager, cx| manager.open_display(display_id, cx));
        }
        observe_display_changes(display_manager.clone(), cx);
        let display_manager_for_requests = display_manager.clone();
        let display_manager_for_refresh = display_manager.clone();
        let display_manager_for_toasts = display_manager.clone();
        let toast_service = notification_service.clone();
        let toast_config = config.clone();
        if let Some(request) = initial_request {
            display_manager.update(cx, |manager, cx| {
                if let Some(bar) = manager.first_bar() {
                    bar.update(cx, |bar, cx| bar.toggle_panel(request, cx));
                }
            });
        }

        cx.spawn(async move |cx| {
            let mut toast_window: Option<WindowHandle<ShellNotificationToast>> = None;
            loop {
                cx.background_executor()
                    .timer(Duration::from_millis(200))
                    .await;
                let notifications = toast_service
                    .snapshot()
                    .into_iter()
                    .filter(|notification| notification.toast_visible())
                    .take(4)
                    .collect::<Vec<_>>();
                cx.update(|cx| {
                    if notifications.is_empty() {
                        if let Some(window) = toast_window.take()
                            && let Err(error) =
                                window.update(cx, |_, window, _| window.remove_window())
                        {
                            eprintln!("Could not close notification toasts: {error}");
                        }
                        return;
                    }

                    let update_result = toast_window.as_ref().map(|window| {
                        window.update(cx, |toast, _, cx| {
                            toast.set_notifications(notifications.clone(), cx)
                        })
                    });
                    if let Some(Err(error)) = update_result {
                        eprintln!("Could not update notification toasts: {error}");
                        toast_window = None;
                    }
                    if toast_window.is_none() {
                        let display_id = display_manager_for_toasts.read(cx).primary_display_id();
                        let options =
                            notification_toast_window_options(cx, &toast_config, display_id);
                        let initial_notifications = notifications.clone();
                        let service = toast_service.clone();
                        match cx.open_window(options, move |_, cx| {
                            cx.new(|cx| {
                                ShellNotificationToast::new(initial_notifications, service, cx)
                            })
                        }) {
                            Ok(window) => toast_window = Some(window),
                            Err(error) => {
                                eprintln!("Could not open notification toasts: {error}")
                            }
                        }
                    }
                });
            }
        })
        .detach();

        cx.spawn(async move |cx| {
            let _socket_guard = socket_guard;
            let mut receiver = receiver;
            while let Some(request) = receiver.recv().await {
                cx.update(|cx| {
                    display_manager_for_requests.update(cx, |manager, cx| {
                        if let Some(bar) = manager.first_bar() {
                            bar.update(cx, |bar, cx| bar.toggle_panel(request, cx));
                        }
                    });
                });
            }
        })
        .detach();

        cx.spawn(async move |cx| {
            let mut battery_monitor = BatteryMonitor::default();
            loop {
                cx.background_executor().timer(Duration::from_secs(2)).await;
                let status = match tokio::task::spawn_blocking(read_status).await {
                    Ok(status) => status,
                    Err(error) => {
                        eprintln!("Could not refresh shell status: {error}");
                        continue;
                    }
                };
                cx.update(|cx| {
                    let shell_config = config_for_status.read(cx).value.clone();
                    notifications_for_status
                        .set_default_timeout(shell_config.notifications.default_timeout);
                    let actions = battery_monitor.update(
                        status.battery,
                        status.battery_charging,
                        &shell_config.battery,
                    );
                    for action in actions {
                        match action {
                            BatteryAction::Low => run_detached(
                                "notify-send",
                                &[
                                    "Low battery",
                                    "Consider plugging in your device",
                                    "--urgency=critical",
                                    "--app-name=Shell",
                                ],
                            ),
                            BatteryAction::Critical => run_detached(
                                "notify-send",
                                &[
                                    "Critically low battery",
                                    "Please charge your device now",
                                    "--urgency=critical",
                                    "--app-name=Shell",
                                ],
                            ),
                            BatteryAction::Suspend => {
                                suspend_system();
                            }
                        }
                    }
                    display_manager_for_refresh.update(cx, |manager, cx| {
                        manager.refresh(&status, cx);
                    });
                });
            }
        })
        .detach();
    });
}
