use gpui::{AppContext, Context, DisplayChanges, DisplayEvent, DisplayId, Entity, WindowHandle};

use crate::{
    config::ConfigStore,
    model::Status,
    services::{NotificationService, TrayService},
};

use super::{ShellBar, ShellWallpaper, bar_window_options, wallpaper_window_options};

struct DisplayWindows {
    display_id: Option<DisplayId>,
    bar: Entity<ShellBar>,
    bar_window: WindowHandle<ShellBar>,
    wallpaper_window: WindowHandle<ShellWallpaper>,
}

pub(crate) struct ShellDisplayManager {
    config: Entity<ConfigStore>,
    tray_service: TrayService,
    notification_service: NotificationService,
    displays: Vec<DisplayWindows>,
}

impl ShellDisplayManager {
    pub(crate) fn new(
        config: Entity<ConfigStore>,
        tray_service: TrayService,
        notification_service: NotificationService,
    ) -> Self {
        Self {
            config,
            tray_service,
            notification_service,
            displays: Vec::new(),
        }
    }

    pub(crate) fn open_display(&mut self, display_id: Option<DisplayId>, cx: &mut Context<Self>) {
        if self
            .displays
            .iter()
            .any(|display| display.display_id == display_id)
        {
            return;
        }
        let options = wallpaper_window_options(cx, display_id);
        let wallpaper_config = self.config.clone();
        let wallpaper_window = match cx.open_window(options, move |_, cx| {
            cx.new(|cx| ShellWallpaper::new(wallpaper_config, cx))
        }) {
            Ok(window) => window,
            Err(error) => {
                eprintln!("Could not open wallpaper on display {display_id:?}: {error}");
                return;
            }
        };
        let bar = cx.new(|cx| {
            ShellBar::new(
                self.config.clone(),
                display_id,
                self.tray_service.clone(),
                self.notification_service.clone(),
                cx,
            )
        });
        let options = bar_window_options(cx, &self.config, display_id);
        match cx.open_window(options, {
            let bar = bar.clone();
            move |_, _| bar.clone()
        }) {
            Ok(bar_window) => self.displays.push(DisplayWindows {
                display_id,
                bar,
                bar_window,
                wallpaper_window,
            }),
            Err(error) => {
                eprintln!("Could not open the shell bar on display {display_id:?}: {error}");
                if let Err(error) =
                    wallpaper_window.update(cx, |_, window, _| window.remove_window())
                {
                    eprintln!("Could not close the orphaned wallpaper window: {error}");
                }
            }
        }
    }

    pub(crate) fn remove_display(&mut self, display_id: DisplayId, cx: &mut Context<Self>) {
        self.close_display(Some(display_id), cx);
        if self.displays.is_empty() {
            self.open_display(None, cx);
        }
    }

    pub(crate) fn display_changed(
        &mut self,
        display_id: DisplayId,
        changes: DisplayChanges,
        cx: &mut Context<Self>,
    ) {
        if changes.contains(DisplayChanges::BOUNDS) {
            self.close_display(Some(display_id), cx);
            self.open_display(Some(display_id), cx);
        }
    }

    pub(crate) fn first_bar(&self) -> Option<Entity<ShellBar>> {
        self.displays.first().map(|display| display.bar.clone())
    }

    pub(crate) fn primary_display_id(&self) -> Option<DisplayId> {
        self.displays.first().and_then(|display| display.display_id)
    }

    pub(crate) fn refresh(&mut self, status: &Status, cx: &mut Context<Self>) {
        let tray_items = self.tray_service.snapshot();
        let now = chrono::Local::now();
        for display in &self.displays {
            display.bar.update(cx, |bar, cx| {
                bar.status = status.clone();
                bar.tray_items = tray_items.clone();
                bar.now = now;
                cx.notify();
            });
        }
    }

    fn close_display(&mut self, display_id: Option<DisplayId>, cx: &mut Context<Self>) {
        let Some(index) = self
            .displays
            .iter()
            .position(|display| display.display_id == display_id)
        else {
            return;
        };
        let display = self.displays.remove(index);
        if let Err(error) = display
            .bar_window
            .update(cx, |_, window, _| window.remove_window())
        {
            eprintln!("Could not close bar on display {display_id:?}: {error}");
        }
        if let Err(error) = display
            .wallpaper_window
            .update(cx, |_, window, _| window.remove_window())
        {
            eprintln!("Could not close wallpaper on display {display_id:?}: {error}");
        }
    }
}

pub(crate) fn observe_display_changes(manager: Entity<ShellDisplayManager>, cx: &mut gpui::App) {
    cx.observe_displays(move |event, cx| match event {
        DisplayEvent::Added(display_id) => {
            manager.update(cx, |manager, cx| {
                manager.close_display(None, cx);
                manager.open_display(Some(display_id), cx);
            });
        }
        DisplayEvent::Removed(display_id) => {
            manager.update(cx, |manager, cx| manager.remove_display(display_id, cx));
        }
        DisplayEvent::Changed { id, changes } => {
            manager.update(cx, |manager, cx| manager.display_changed(id, changes, cx));
        }
        _ => {}
    })
    .detach();
}
