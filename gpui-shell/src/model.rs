use std::collections::HashMap;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(crate) enum PanelKind {
    Overview,
    Clipboard,
    Cheatsheet,
    Notifications,
    Notes,
    Settings,
    Audio,
    Session,
}

impl PanelKind {
    pub(crate) fn key(self) -> &'static str {
        match self {
            Self::Overview => "overview",
            Self::Clipboard => "clipboard",
            Self::Cheatsheet => "cheatsheet",
            Self::Notifications => "notifications",
            Self::Notes => "notes",
            Self::Settings => "settings",
            Self::Audio => "audio",
            Self::Session => "session",
        }
    }

    pub(crate) fn from_key(value: &str) -> Option<Self> {
        Some(match value {
            "overview" | "toggle" | "launcher" => Self::Overview,
            "clipboard" => Self::Clipboard,
            "cheatsheet" => Self::Cheatsheet,
            "notifications" => Self::Notifications,
            "notes" => Self::Notes,
            "settings" => Self::Settings,
            "audio" => Self::Audio,
            "session" => Self::Session,
            _ => return None,
        })
    }

    pub(crate) fn title(self) -> &'static str {
        match self {
            Self::Overview => "Aktyn shell",
            Self::Clipboard => "Clipboard history",
            Self::Cheatsheet => "Keyboard shortcuts",
            Self::Notifications => "Notifications",
            Self::Notes => "Notes",
            Self::Settings => "Quick settings",
            Self::Audio => "Audio",
            Self::Session => "Session",
        }
    }
}

#[derive(Clone, Copy, Eq, PartialEq)]
pub(crate) enum MainTab {
    Apps,
    TimeTools,
    Options,
}

#[derive(Clone, Default)]
pub(crate) struct Status {
    pub(crate) active_window_app_id: String,
    pub(crate) active_window: String,
    pub(crate) night_light_enabled: bool,
    pub(crate) workspace: Option<i32>,
    pub(crate) occupied_workspaces: Vec<i32>,
    pub(crate) workspace_app_classes: HashMap<i32, Vec<String>>,
    pub(crate) battery: Option<u8>,
    pub(crate) battery_charging: bool,
    pub(crate) cpu: Option<u8>,
    pub(crate) memory: Option<u8>,
    pub(crate) swap: Option<u8>,
    pub(crate) download_bps: Option<u64>,
    pub(crate) upload_bps: Option<u64>,
    pub(crate) volume: Option<u8>,
    pub(crate) muted: bool,
    pub(crate) media: Option<String>,
    pub(crate) bluetooth_enabled: bool,
    pub(crate) bluetooth_connected: bool,
}

pub(crate) struct DesktopApp {
    pub(crate) name: String,
    pub(crate) id: String,
    pub(crate) comment: Option<String>,
    pub(crate) icon: Option<std::path::PathBuf>,
}

pub(crate) struct ClipboardEntry {
    pub(crate) id: String,
    pub(crate) text: String,
}
