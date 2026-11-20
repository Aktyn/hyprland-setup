mod apps;
mod battery;
mod clipboard;
mod commands;
mod hyprland;
mod media;
mod notes;
mod notifications;
mod status;
mod system;
mod tray;

pub(crate) use apps::{
    find_app_icon, fuzzy_score, launch_app, load_apps, read_recent_apps, record_recent_app,
};
pub(crate) use battery::{BatteryAction, BatteryMonitor};
pub(crate) use clipboard::{copy_clipboard_entry, read_clipboard_history};
pub(crate) use commands::run_detached;
pub(crate) use hyprland::{dispatch, read_shortcuts};
pub(crate) use media::{control_media_player, read_media_players};
pub(crate) use notes::{notes_path, open_notes};
pub(crate) use notifications::{Notification, NotificationService};
pub(crate) use status::read_status;
pub(crate) use system::{suspend_system, toggle_bluetooth, toggle_night_light};
pub(crate) use tray::{TrayIcon, TrayItem, TrayMenuEntry, TrayService};
