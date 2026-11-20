use gpui::rgba;
use serde::Deserialize;
use std::{
    collections::HashMap,
    fs,
    path::{Path, PathBuf},
    process::Command,
    sync::RwLock,
};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub(crate) struct Theme {
    pub(crate) background: u32,
    pub(crate) surface: u32,
    pub(crate) surface_dim: u32,
    pub(crate) surface_bright: u32,
    pub(crate) surface_high: u32,
    pub(crate) surface_highest: u32,
    pub(crate) surface_variant: u32,
    pub(crate) outline: u32,
    pub(crate) outline_variant: u32,
    pub(crate) foreground: u32,
    pub(crate) muted: u32,
    pub(crate) primary: u32,
    pub(crate) on_primary: u32,
    pub(crate) primary_container: u32,
    pub(crate) on_primary_container: u32,
    pub(crate) inverse_primary: u32,
    pub(crate) secondary: u32,
    pub(crate) on_secondary: u32,
    pub(crate) secondary_container: u32,
    pub(crate) on_secondary_container: u32,
    pub(crate) tertiary: u32,
    pub(crate) error: u32,
    pub(crate) error_container: u32,
}

pub(crate) const DEFAULT_THEME: Theme = Theme {
    background: 0x131318,
    surface: 0x1f1f25, // surfaceContainer in QML
    surface_dim: 0x131318,
    surface_bright: 0x39383f,
    surface_high: 0x2a292f,      // surfaceContainerHigh in QML
    surface_highest: 0x35343a,   // surfaceContainerHighest in QML
    surface_variant: 0x46464f,   // surfaceVariant in QML
    outline: 0x918f9a,           // outline in QML
    outline_variant: 0x46464f,   // outlineVariant in QML
    foreground: 0xe4e1e9,        // colorOnSurface in QML
    muted: 0xc7c5d0,             // colorOnSurfaceVariant in QML
    primary: 0xbfc2ff,           // primary in QML
    on_primary: 0x272b60,        // colorOnPrimary in QML
    primary_container: 0x3e4278, // primaryContainer in QML
    on_primary_container: 0xe0e0ff,
    inverse_primary: 0x565992,
    secondary: 0xc5c4dd,
    on_secondary: 0x2e2f42,
    secondary_container: 0x444559,
    on_secondary_container: 0xe1e0f9,
    tertiary: 0xe8b9d4,
    error: 0xffb4ab,
    error_container: 0x93000a,
};

#[allow(dead_code)]
pub(crate) const BACKGROUND: u32 = DEFAULT_THEME.background;
#[allow(dead_code)]
pub(crate) const SURFACE: u32 = DEFAULT_THEME.surface;
#[allow(dead_code)]
pub(crate) const SURFACE_HIGH: u32 = DEFAULT_THEME.surface_high;
#[allow(dead_code)]
pub(crate) const OUTLINE: u32 = DEFAULT_THEME.outline;
#[allow(dead_code)]
pub(crate) const FOREGROUND: u32 = DEFAULT_THEME.foreground;
#[allow(dead_code)]
pub(crate) const MUTED: u32 = DEFAULT_THEME.muted;
#[allow(dead_code)]
pub(crate) const PRIMARY: u32 = DEFAULT_THEME.primary;
#[allow(dead_code)]
pub(crate) const ON_PRIMARY: u32 = DEFAULT_THEME.on_primary;

static CURRENT_THEME: RwLock<Theme> = RwLock::new(DEFAULT_THEME);

pub(crate) fn theme() -> Theme {
    *CURRENT_THEME
        .read()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}

pub(crate) fn set_theme(theme: Theme) {
    if let Ok(mut current) = CURRENT_THEME.write() {
        *current = theme;
    }
}

#[allow(dead_code)]
pub(crate) fn background() -> u32 {
    theme().background
}

pub(crate) fn surface() -> u32 {
    theme().surface
}

pub(crate) fn surface_high() -> u32 {
    theme().surface_high
}

#[allow(dead_code)]
pub(crate) fn surface_highest() -> u32 {
    theme().surface_highest
}

#[allow(dead_code)]
pub(crate) fn surface_variant() -> u32 {
    theme().surface_variant
}

pub(crate) fn outline() -> u32 {
    theme().outline
}

#[allow(dead_code)]
pub(crate) fn outline_variant() -> u32 {
    theme().outline_variant
}

pub(crate) fn foreground() -> u32 {
    theme().foreground
}

pub(crate) fn muted() -> u32 {
    theme().muted
}

pub(crate) fn primary() -> u32 {
    theme().primary
}

pub(crate) fn on_primary() -> u32 {
    theme().on_primary
}

#[allow(dead_code)]
pub(crate) fn primary_container() -> u32 {
    theme().primary_container
}

#[allow(dead_code)]
pub(crate) fn on_primary_container() -> u32 {
    theme().on_primary_container
}

#[allow(dead_code)]
pub(crate) fn inverse_primary() -> u32 {
    theme().inverse_primary
}

#[allow(dead_code)]
pub(crate) fn secondary() -> u32 {
    theme().secondary
}

#[allow(dead_code)]
pub(crate) fn on_secondary() -> u32 {
    theme().on_secondary
}

#[allow(dead_code)]
pub(crate) fn secondary_container() -> u32 {
    theme().secondary_container
}

#[allow(dead_code)]
pub(crate) fn on_secondary_container() -> u32 {
    theme().on_secondary_container
}

#[allow(dead_code)]
pub(crate) fn tertiary() -> u32 {
    theme().tertiary
}

pub(crate) fn error() -> u32 {
    theme().error
}

#[allow(dead_code)]
pub(crate) fn error_container() -> u32 {
    theme().error_container
}

pub(crate) fn surface_with_opacity(opacity: f32) -> gpui::Rgba {
    let alpha = (opacity.clamp(0.0, 1.0) * 255.0).round() as u32;
    rgba((surface() << 8) | alpha)
}

pub(crate) fn parse_hex(hex: &str) -> Option<u32> {
    let clean = hex.trim().trim_start_matches('#');
    if clean.len() >= 6 {
        u32::from_str_radix(&clean[..6], 16).ok()
    } else {
        None
    }
}

#[derive(Debug, Deserialize)]
struct ColorsJson {
    #[serde(default)]
    wallpaper: Option<String>,
    #[serde(default)]
    colors: HashMap<String, String>,
}

pub(crate) fn parse_colors_json(json_str: &str) -> Option<Theme> {
    let parsed: ColorsJson = serde_json::from_str(json_str).ok()?;
    let colors = parsed.colors;

    let get = |key: &str| -> Option<u32> { colors.get(key).and_then(|val| parse_hex(val)) };

    let background = get("background")
        .or_else(|| get("surface"))
        .unwrap_or(DEFAULT_THEME.background);
    let surface = get("surfaceContainer")
        .or_else(|| get("surface"))
        .unwrap_or(DEFAULT_THEME.surface);
    let surface_dim = get("surfaceDim").unwrap_or(DEFAULT_THEME.surface_dim);
    let surface_bright = get("surfaceBright").unwrap_or(DEFAULT_THEME.surface_bright);
    let surface_high = get("surfaceContainerHigh")
        .or_else(|| get("surfaceVariant"))
        .unwrap_or(DEFAULT_THEME.surface_high);
    let surface_highest = get("surfaceContainerHighest").unwrap_or(DEFAULT_THEME.surface_highest);
    let surface_variant = get("surfaceVariant").unwrap_or(DEFAULT_THEME.surface_variant);
    let outline = get("outline").unwrap_or(DEFAULT_THEME.outline);
    let outline_variant = get("outlineVariant").unwrap_or(DEFAULT_THEME.outline_variant);
    let foreground = get("colorOnSurface").unwrap_or(DEFAULT_THEME.foreground);
    let muted = get("colorOnSurfaceVariant").unwrap_or(DEFAULT_THEME.muted);
    let primary = get("primary").unwrap_or(DEFAULT_THEME.primary);
    let on_primary = get("colorOnPrimary").unwrap_or(DEFAULT_THEME.on_primary);
    let primary_container = get("primaryContainer").unwrap_or(DEFAULT_THEME.primary_container);
    let on_primary_container =
        get("colorOnPrimaryContainer").unwrap_or(DEFAULT_THEME.on_primary_container);
    let inverse_primary = get("inversePrimary").unwrap_or(DEFAULT_THEME.inverse_primary);
    let secondary = get("secondary").unwrap_or(DEFAULT_THEME.secondary);
    let on_secondary = get("colorOnSecondary").unwrap_or(DEFAULT_THEME.on_secondary);
    let secondary_container =
        get("secondaryContainer").unwrap_or(DEFAULT_THEME.secondary_container);
    let on_secondary_container =
        get("colorOnSecondaryContainer").unwrap_or(DEFAULT_THEME.on_secondary_container);
    let tertiary = get("tertiary").unwrap_or(DEFAULT_THEME.tertiary);
    let error = get("error").unwrap_or(DEFAULT_THEME.error);
    let error_container = get("errorContainer").unwrap_or(DEFAULT_THEME.error_container);

    Some(Theme {
        background,
        surface,
        surface_dim,
        surface_bright,
        surface_high,
        surface_highest,
        surface_variant,
        outline,
        outline_variant,
        foreground,
        muted,
        primary,
        on_primary,
        primary_container,
        on_primary_container,
        inverse_primary,
        secondary,
        on_secondary,
        secondary_container,
        on_secondary_container,
        tertiary,
        error,
        error_container,
    })
}

pub(crate) fn cache_colors_paths() -> Vec<PathBuf> {
    let mut paths = Vec::new();
    if let Some(cache_home) = std::env::var_os("XDG_CACHE_HOME").map(PathBuf::from) {
        paths.push(cache_home.join("aktyn-quickshell").join("colors.json"));
        paths.push(cache_home.join("aktyn-shell").join("colors.json"));
    }
    if let Some(home) = std::env::var_os("HOME").map(PathBuf::from) {
        paths.push(
            home.join(".cache")
                .join("aktyn-quickshell")
                .join("colors.json"),
        );
        paths.push(home.join(".cache").join("aktyn-shell").join("colors.json"));
    }
    paths
}

pub(crate) fn find_generator_script() -> Option<PathBuf> {
    if let Some(script) = std::env::var_os("AKTYN_PALETTE_SCRIPT").map(PathBuf::from) {
        if script.is_file() {
            return Some(script);
        }
    }
    if let Some(home) = std::env::var_os("HOME").map(PathBuf::from) {
        let installed =
            home.join(".local/share/aktyn-shell/scripts/generate-material-you-colors.py");
        if installed.is_file() {
            return Some(installed);
        }
    }
    let candidates = [
        "quickshell/scripts/generate-material-you-colors.py",
        "../quickshell/scripts/generate-material-you-colors.py",
        "../../quickshell/scripts/generate-material-you-colors.py",
    ];
    for candidate in candidates {
        let path = PathBuf::from(candidate);
        if path.is_file() {
            return Some(path);
        }
    }
    None
}

pub(crate) fn load_cached_theme() -> Option<(Theme, Option<String>)> {
    for path in cache_colors_paths() {
        if let Ok(content) = fs::read_to_string(&path) {
            if let Some(theme) = parse_colors_json(&content) {
                let wallpaper = serde_json::from_str::<ColorsJson>(&content)
                    .ok()
                    .and_then(|c| c.wallpaper);
                return Some((theme, wallpaper));
            }
        }
    }
    None
}

pub(crate) fn generate_and_load_theme(wallpaper_path: &str) -> Result<Theme, String> {
    let script = find_generator_script()
        .ok_or_else(|| "Could not locate generate-material-you-colors.py script".to_string())?;

    let cache_path = cache_colors_paths()
        .into_iter()
        .next()
        .unwrap_or_else(|| PathBuf::from("/tmp/aktyn-shell-colors.json"));

    if let Some(parent) = cache_path.parent() {
        let _ = fs::create_dir_all(parent);
    }

    let status = Command::new("python")
        .arg(&script)
        .arg(wallpaper_path)
        .arg(&cache_path)
        .status()
        .map_err(|e| format!("Failed to execute python palette script: {e}"))?;

    if !status.success() {
        return Err(format!(
            "Palette script exited with status {:?}",
            status.code()
        ));
    }

    let content = fs::read_to_string(&cache_path).map_err(|e| {
        format!(
            "Failed to read generated colors file {}: {e}",
            cache_path.display()
        )
    })?;

    parse_colors_json(&content).ok_or_else(|| "Failed to parse generated colors JSON".to_string())
}

pub(crate) fn sync_theme_with_wallpaper(wallpaper_path: Option<&str>) {
    let wallpaper = wallpaper_path.map(str::trim).filter(|w| !w.is_empty());

    if let Some((cached_theme, cached_wallpaper)) = load_cached_theme() {
        if let Some(req_wp) = wallpaper {
            if cached_wallpaper.as_deref() == Some(req_wp) {
                set_theme(cached_theme);
                return;
            }
        } else {
            set_theme(cached_theme);
            return;
        }
    }

    if let Some(wp) = wallpaper {
        if Path::new(wp).exists() {
            match generate_and_load_theme(wp) {
                Ok(generated) => {
                    set_theme(generated);
                    return;
                }
                Err(err) => {
                    eprintln!("Warning: Could not generate Material You colors for {wp}: {err}");
                }
            }
        }
    }

    if let Some((cached_theme, _)) = load_cached_theme() {
        set_theme(cached_theme);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_hex() {
        assert_eq!(parse_hex("#131318"), Some(0x131318));
        assert_eq!(parse_hex("bfc2ff"), Some(0xbfc2ff));
        assert_eq!(parse_hex("invalid"), None);
    }

    #[test]
    fn test_parse_colors_json() {
        let sample = r##"{
            "wallpaper": "/some/wall.jpg",
            "colors": {
                "surfaceContainer": "#1a1a11",
                "surfaceContainerHigh": "#202016",
                "colorOnSurface": "#e9e6d3",
                "colorOnSurfaceVariant": "#adac9a",
                "primary": "#caca8f",
                "colorOnPrimary": "#414215",
                "outline": "#777666"
            }
        }"##;
        let theme = parse_colors_json(sample).expect("parse sample");
        assert_eq!(theme.surface, 0x1a1a11);
        assert_eq!(theme.surface_high, 0x202016);
        assert_eq!(theme.foreground, 0xe9e6d3);
        assert_eq!(theme.muted, 0xadac9a);
        assert_eq!(theme.primary, 0xcaca8f);
        assert_eq!(theme.on_primary, 0x414215);
        assert_eq!(theme.outline, 0x777666);
    }
}
