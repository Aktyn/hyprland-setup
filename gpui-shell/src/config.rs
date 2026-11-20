use std::{fs, path::PathBuf};

use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(default)]
pub(crate) struct ShellConfig {
    pub(crate) general: GeneralConfig,
    pub(crate) bar: BarConfig,
    pub(crate) wallpaper: WallpaperConfig,
    pub(crate) battery: BatteryConfig,
    pub(crate) notifications: NotificationsConfig,
    pub(crate) apps: AppsConfig,
    pub(crate) workspaces: WorkspacesConfig,
}

impl Default for ShellConfig {
    fn default() -> Self {
        Self {
            general: GeneralConfig::default(),
            bar: BarConfig::default(),
            wallpaper: WallpaperConfig::default(),
            battery: BatteryConfig::default(),
            notifications: NotificationsConfig::default(),
            apps: AppsConfig::default(),
            workspaces: WorkspacesConfig::default(),
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(default, rename_all = "camelCase")]
pub(crate) struct GeneralConfig {
    #[serde(alias = "hide_author_link")]
    pub(crate) hide_author_link: bool,
    #[serde(alias = "updates_check_interval")]
    pub(crate) updates_check_interval: u64,
    #[serde(alias = "panels_transparency")]
    pub(crate) panels_transparency: f32,
}

impl Default for GeneralConfig {
    fn default() -> Self {
        Self {
            hide_author_link: false,
            updates_check_interval: 60 * 60 * 1000,
            panels_transparency: 0.66,
        }
    }
}

#[derive(Clone, Debug, Default, Deserialize, Serialize)]
#[serde(default, rename_all = "camelCase")]
pub(crate) struct QuickLauncherConfig {
    #[serde(alias = "pinned_apps")]
    pub(crate) pinned_apps: Vec<String>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(default, rename_all = "camelCase")]
pub(crate) struct BarConfig {
    #[serde(alias = "screen_list")]
    pub(crate) screen_list: Vec<String>,
    pub(crate) height: u32,
    #[serde(alias = "shadow_opacity")]
    pub(crate) shadow_opacity: f32,
    #[serde(alias = "desaturate_tray_icons")]
    pub(crate) desaturate_tray_icons: f32,
    #[serde(alias = "panel_slide_duration")]
    pub(crate) panel_slide_duration: u64,
    #[serde(alias = "pinned_apps")]
    pub(crate) pinned_apps: Vec<String>,
    #[serde(alias = "quick_launcher")]
    pub(crate) quick_launcher: Option<QuickLauncherConfig>,
}

impl Default for BarConfig {
    fn default() -> Self {
        Self {
            screen_list: Vec::new(),
            height: 36,
            shadow_opacity: 1.0,
            desaturate_tray_icons: 0.5,
            panel_slide_duration: 350,
            pinned_apps: Vec::new(),
            quick_launcher: None,
        }
    }
}

#[derive(Clone, Debug, Default, Deserialize, Serialize)]
#[serde(default, rename_all = "camelCase")]
pub(crate) struct WallpaperConfig {
    pub(crate) path: String,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(default, rename_all = "camelCase")]
pub(crate) struct BatteryConfig {
    pub(crate) low: u8,
    pub(crate) critical: u8,
    pub(crate) suspend: u8,
    #[serde(alias = "automatic_suspend")]
    pub(crate) automatic_suspend: bool,
}

impl Default for BatteryConfig {
    fn default() -> Self {
        Self {
            low: 20,
            critical: 5,
            suspend: 3,
            automatic_suspend: true,
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(default, rename_all = "camelCase")]
pub(crate) struct NotificationsConfig {
    #[serde(alias = "default_timeout")]
    pub(crate) default_timeout: u64,
}

impl Default for NotificationsConfig {
    fn default() -> Self {
        Self {
            default_timeout: 8000,
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(default, rename_all = "camelCase")]
pub(crate) struct AppsConfig {
    pub(crate) bluetooth: String,
}

impl Default for AppsConfig {
    fn default() -> Self {
        Self {
            bluetooth: "blueman-manager".into(),
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(default, rename_all = "camelCase")]
pub(crate) struct WorkspacesConfig {
    pub(crate) count: u32,
}

impl Default for WorkspacesConfig {
    fn default() -> Self {
        Self { count: 6 }
    }
}

#[derive(Clone, Copy)]
pub(crate) enum SettingField {
    HideAuthorLink,
    AutomaticSuspend,
    Transparency,
    BarHeight,
    ShadowOpacity,
    TrayDesaturation,
    PanelAnimation,
    WorkspaceCount,
    NotificationTimeout,
    BatteryLow,
    BatteryCritical,
    BatterySuspend,
}

#[derive(Clone)]
pub(crate) struct ConfigStore {
    pub(crate) value: ShellConfig,
}

impl ConfigStore {
    pub(crate) fn load() -> Self {
        let path = config_path();
        let mut value = match fs::read(&path) {
            Ok(data) => match serde_json::from_slice::<ShellConfig>(&data) {
                Ok(val) => val,
                Err(error) => {
                    eprintln!("Could not parse shell config {}: {error}", path.display());
                    ShellConfig::default()
                }
            },
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => ShellConfig::default(),
            Err(error) => {
                eprintln!("Could not read shell config {}: {error}", path.display());
                ShellConfig::default()
            }
        };

        if value.bar.pinned_apps.is_empty() {
            if let Some(ql) = &value.bar.quick_launcher {
                value.bar.pinned_apps = ql.pinned_apps.clone();
            }
        }

        crate::ui::theme::sync_theme_with_wallpaper(Some(&value.wallpaper.path));

        Self { value }
    }

    pub(crate) fn save(&self) {
        let path = config_path();
        let Some(parent) = path.parent() else {
            eprintln!("Shell config path has no parent: {}", path.display());
            return;
        };
        if let Err(error) = fs::create_dir_all(parent) {
            eprintln!(
                "Could not create shell config directory {}: {error}",
                parent.display()
            );
            return;
        }

        let mut to_save = self.value.clone();
        to_save.bar.quick_launcher = Some(QuickLauncherConfig {
            pinned_apps: to_save.bar.pinned_apps.clone(),
        });

        let temporary_path = path.with_extension("json.tmp");
        let result = serde_json::to_vec_pretty(&to_save)
            .map_err(std::io::Error::other)
            .and_then(|data| fs::write(&temporary_path, data))
            .and_then(|()| fs::rename(&temporary_path, &path));
        if let Err(error) = result {
            eprintln!("Could not save shell config {}: {error}", path.display());
        }
    }

    pub(crate) fn adjust(&mut self, field: SettingField, amount: i32) {
        match field {
            SettingField::HideAuthorLink | SettingField::AutomaticSuspend => {}
            SettingField::Transparency => {
                self.value.general.panels_transparency = clamp_float(
                    self.value.general.panels_transparency,
                    amount,
                    0.0,
                    1.0,
                    0.05,
                )
            }
            SettingField::BarHeight => {
                self.value.bar.height =
                    clamp_integer(self.value.bar.height.into(), amount, 24, 72, 1) as u32
            }
            SettingField::ShadowOpacity => {
                self.value.bar.shadow_opacity =
                    clamp_float(self.value.bar.shadow_opacity, amount, 0.0, 1.0, 0.05)
            }
            SettingField::TrayDesaturation => {
                self.value.bar.desaturate_tray_icons =
                    clamp_float(self.value.bar.desaturate_tray_icons, amount, 0.0, 1.0, 0.05)
            }
            SettingField::PanelAnimation => {
                self.value.bar.panel_slide_duration =
                    clamp_integer(self.value.bar.panel_slide_duration, amount, 100, 1000, 50)
            }
            SettingField::WorkspaceCount => {
                self.value.workspaces.count =
                    clamp_integer(self.value.workspaces.count.into(), amount, 1, 10, 1) as u32
            }
            SettingField::NotificationTimeout => {
                self.value.notifications.default_timeout = clamp_integer(
                    self.value.notifications.default_timeout,
                    amount,
                    1000,
                    20_000,
                    1000,
                )
            }
            SettingField::BatteryLow => {
                self.value.battery.low =
                    clamp_integer(self.value.battery.low.into(), amount, 5, 50, 1) as u8
            }
            SettingField::BatteryCritical => {
                self.value.battery.critical =
                    clamp_integer(self.value.battery.critical.into(), amount, 2, 20, 1) as u8
            }
            SettingField::BatterySuspend => {
                self.value.battery.suspend =
                    clamp_integer(self.value.battery.suspend.into(), amount, 1, 10, 1) as u8
            }
        }
    }

    pub(crate) fn toggle(&mut self, field: SettingField) {
        match field {
            SettingField::HideAuthorLink => {
                self.value.general.hide_author_link = !self.value.general.hide_author_link;
            }
            SettingField::AutomaticSuspend => {
                self.value.battery.automatic_suspend = !self.value.battery.automatic_suspend;
            }
            _ => return,
        }
        self.save();
    }
}

pub(crate) fn config_path() -> PathBuf {
    let config_dir = std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .or_else(|| std::env::var_os("HOME").map(|home| PathBuf::from(home).join(".config")))
        .unwrap_or_else(std::env::temp_dir);
    config_dir.join("aktyn-quickshell").join("config.json")
}

fn clamp_float(value: f32, amount: i32, minimum: f32, maximum: f32, step: f32) -> f32 {
    let next = value + amount as f32 * step;
    (next * 100.0)
        .round()
        .clamp(minimum * 100.0, maximum * 100.0)
        / 100.0
}

fn clamp_integer(value: u64, amount: i32, minimum: u64, maximum: u64, step: u64) -> u64 {
    (value as i64 + i64::from(amount) * step as i64).clamp(minimum as i64, maximum as i64) as u64
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn defaults_match_the_quickshell_configuration() {
        let config = ShellConfig::default();
        assert_eq!(config.bar.height, 36);
        assert_eq!(config.workspaces.count, 6);
        assert_eq!(config.battery.low, 20);
        assert_eq!(config.notifications.default_timeout, 8000);
    }

    #[test]
    fn setting_adjustments_are_clamped_and_stepwise() {
        let mut store = ConfigStore {
            value: ShellConfig::default(),
        };
        store.adjust(SettingField::WorkspaceCount, 1);
        assert_eq!(store.value.workspaces.count, 7);
        for _ in 0..20 {
            store.adjust(SettingField::WorkspaceCount, 1);
        }
        assert_eq!(store.value.workspaces.count, 10);
        store.adjust(SettingField::Transparency, 1);
        assert!((store.value.general.panels_transparency - 0.71).abs() < 0.001);
        for _ in 0..20 {
            store.adjust(SettingField::BatterySuspend, 1);
        }
        assert_eq!(store.value.battery.suspend, 10);
    }

    #[test]
    fn parses_quickshell_camel_case_json() {
        let json = r#"{
            "apps": { "bluetooth": "blueman-manager" },
            "bar": {
                "desaturateTrayIcons": 0.5,
                "height": 36,
                "panelSlideDuration": 350,
                "quickLauncher": {
                    "pinnedApps": ["nvim-kitty", "steam"]
                },
                "screenList": ["DP-1"],
                "shadowOpacity": 1.0
            },
            "battery": { "automaticSuspend": true, "critical": 5, "low": 20, "suspend": 3 },
            "general": { "hideAuthorLink": true, "panelsTransparency": 0.8, "updatesCheckInterval": 3600000 },
            "notifications": { "defaultTimeout": 8000 },
            "wallpaper": { "path": "/home/test/wall.jpg" },
            "workspaces": { "count": 8 }
        }"#;

        let parsed: ShellConfig = serde_json::from_str(json).expect("parse camelCase json");
        assert_eq!(parsed.bar.height, 36);
        assert_eq!(
            parsed.bar.quick_launcher.as_ref().unwrap().pinned_apps,
            vec!["nvim-kitty", "steam"]
        );
        assert_eq!(parsed.general.hide_author_link, true);
        assert_eq!(parsed.workspaces.count, 8);
        assert_eq!(parsed.wallpaper.path, "/home/test/wall.jpg");
    }
}
