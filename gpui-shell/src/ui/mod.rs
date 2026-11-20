mod bar;
mod displays;
mod notification_toast;
mod panel;
pub(crate) mod theme;
mod tray_menu;
mod wallpaper;
mod widgets;
mod windows;

pub(crate) use bar::ShellBar;
pub(crate) use displays::{ShellDisplayManager, observe_display_changes};
pub(crate) use notification_toast::ShellNotificationToast;
pub(crate) use panel::ShellPanel;
pub(crate) use tray_menu::ShellTrayMenu;
pub(crate) use wallpaper::{ShellWallpaper, wallpaper_window_options};
pub(crate) use widgets::{
    action_row, action_row_content, app_icon_name, bar_button, bar_icon_button, calendar_grid,
    material_icon, surface_card,
};
pub(crate) use windows::{
    bar_window_options, notification_toast_window_options, panel_window_options,
    tray_menu_window_options,
};
