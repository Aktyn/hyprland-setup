use std::{
    collections::HashMap,
    fs,
    path::{Path, PathBuf},
    process::Command,
    sync::OnceLock,
};

use crate::model::DesktopApp;

pub(crate) fn load_apps() -> Vec<DesktopApp> {
    let mut directories = vec![
        PathBuf::from("/usr/share/applications"),
        PathBuf::from("/usr/local/share/applications"),
    ];
    if let Some(home) = std::env::var_os("HOME") {
        directories.push(PathBuf::from(home).join(".local/share/applications"));
    }

    let mut apps = Vec::new();
    for directory in directories {
        let Ok(entries) = fs::read_dir(directory) else {
            continue;
        };
        for entry in entries.flatten() {
            let path = entry.path();
            if path.extension().and_then(|ext| ext.to_str()) != Some("desktop") {
                continue;
            }
            let Ok(contents) = fs::read_to_string(&path) else {
                continue;
            };
            let mut in_entry = false;
            let mut name = None;
            let mut comment = None;
            let mut icon = None;
            let mut no_display = false;
            for line in contents.lines() {
                if line.starts_with('[') {
                    in_entry = line == "[Desktop Entry]";
                    continue;
                }
                if !in_entry {
                    continue;
                }
                if let Some(value) = line.strip_prefix("Name=") {
                    name.get_or_insert_with(|| value.to_owned());
                } else if let Some(value) = line.strip_prefix("Comment=") {
                    comment.get_or_insert_with(|| value.to_owned());
                } else if let Some(value) = line.strip_prefix("Icon=") {
                    icon.get_or_insert_with(|| value.to_owned());
                } else if line == "NoDisplay=true" || line == "Hidden=true" {
                    no_display = true;
                }
            }
            if no_display {
                continue;
            }
            let Some(name) = name.filter(|name| !name.trim().is_empty()) else {
                continue;
            };
            let Some(id) = path.file_stem().and_then(|stem| stem.to_str()) else {
                continue;
            };
            apps.push(DesktopApp {
                name,
                id: id.to_owned(),
                comment,
                icon: icon.as_deref().and_then(resolve_icon_path),
            });
        }
    }
    apps.sort_by(|left, right| left.name.to_lowercase().cmp(&right.name.to_lowercase()));
    apps.dedup_by(|left, right| left.id == right.id);
    apps
}

pub(crate) fn find_app_icon(app_id: &str) -> Option<PathBuf> {
    let clean = app_id.trim_end_matches(".desktop");
    if let Some(path) = resolve_icon_path(clean) {
        return Some(path);
    }
    for app in load_apps() {
        if app.id.eq_ignore_ascii_case(app_id) || app.id.eq_ignore_ascii_case(clean) {
            if let Some(icon) = app.icon {
                return Some(icon);
            }
        }
    }
    None
}

fn resolve_icon_path(icon_name: &str) -> Option<PathBuf> {
    let path = Path::new(icon_name);
    if path.is_absolute() && path.is_file() {
        return Some(path.to_path_buf());
    }
    let name = path.file_stem()?.to_str()?.to_lowercase();
    icon_index().get(&name).cloned()
}

fn icon_index() -> &'static HashMap<String, PathBuf> {
    static ICON_INDEX: OnceLock<HashMap<String, PathBuf>> = OnceLock::new();
    ICON_INDEX.get_or_init(|| {
        let mut roots = vec![
            PathBuf::from("/usr/share/icons"),
            PathBuf::from("/usr/local/share/icons"),
        ];
        if let Some(home) = std::env::var_os("HOME") {
            roots.push(PathBuf::from(home).join(".local/share/icons"));
        }
        if let Some(data_home) = std::env::var_os("XDG_DATA_HOME") {
            roots.push(PathBuf::from(data_home).join("icons"));
        }
        let icon_directories = [
            "scalable/apps",
            "128x128/apps",
            "96x96/apps",
            "64x64/apps",
            "48x48/apps",
            "32x32/apps",
            "24x24/apps",
            "16x16/apps",
            "symbolic/apps",
        ];
        let extensions = ["png", "svg", "xpm"];
        let mut icons = HashMap::new();
        for root in roots {
            let Ok(themes) = fs::read_dir(root) else {
                continue;
            };
            let mut themes = themes
                .flatten()
                .map(|entry| entry.path())
                .collect::<Vec<_>>();
            themes.sort_by_key(|path| {
                usize::from(path.file_name().and_then(|name| name.to_str()) != Some("hicolor"))
            });
            for theme in themes {
                for directory in icon_directories {
                    let directory = theme.join(directory);
                    let Ok(entries) = fs::read_dir(&directory) else {
                        continue;
                    };
                    for entry in entries.flatten() {
                        let path = entry.path();
                        if !path.is_file()
                            || !path
                                .extension()
                                .and_then(|extension| extension.to_str())
                                .is_some_and(|extension| extensions.contains(&extension))
                        {
                            continue;
                        }
                        if let Some(name) = path.file_stem().and_then(|name| name.to_str()) {
                            icons.entry(name.to_lowercase()).or_insert(path);
                        }
                    }
                }
            }
        }
        for directory in [PathBuf::from("/usr/share/pixmaps")] {
            let Ok(entries) = fs::read_dir(directory) else {
                continue;
            };
            for entry in entries.flatten() {
                let path = entry.path();
                if path
                    .extension()
                    .and_then(|extension| extension.to_str())
                    .is_some_and(|extension| extensions.contains(&extension))
                    && let Some(name) = path.file_stem().and_then(|name| name.to_str())
                {
                    icons.entry(name.to_lowercase()).or_insert(path);
                }
            }
        }
        icons
    })
}

pub(crate) fn launch_app(id: &str) -> bool {
    match Command::new("gtk-launch").arg(id).spawn() {
        Ok(_) => true,
        Err(error) => {
            eprintln!("Could not launch {id}: {error}");
            false
        }
    }
}

pub(crate) fn read_recent_apps() -> Vec<String> {
    let path = recent_apps_path();
    match fs::read(&path) {
        Ok(data) => match serde_json::from_slice::<Vec<String>>(&data) {
            Ok(apps) => apps,
            Err(error) => {
                eprintln!("Could not parse app history {}: {error}", path.display());
                Vec::new()
            }
        },
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Vec::new(),
        Err(error) => {
            eprintln!("Could not read app history {}: {error}", path.display());
            Vec::new()
        }
    }
}

pub(crate) fn record_recent_app(name: &str) -> Vec<String> {
    let mut apps = read_recent_apps();
    apps.retain(|app| app != name);
    apps.push(name.to_owned());
    apps.truncate(128);
    let path = recent_apps_path();
    if let Some(parent) = path.parent()
        && let Err(error) = fs::create_dir_all(parent)
    {
        eprintln!(
            "Could not create app history directory {}: {error}",
            parent.display()
        );
        return apps;
    }
    match serde_json::to_vec_pretty(&apps) {
        Ok(data) => {
            if let Err(error) = fs::write(&path, data) {
                eprintln!("Could not save app history {}: {error}", path.display());
            }
        }
        Err(error) => eprintln!("Could not serialize app history: {error}"),
    }
    apps
}

fn recent_apps_path() -> PathBuf {
    let cache_dir = std::env::var_os("XDG_CACHE_HOME")
        .map(PathBuf::from)
        .or_else(|| std::env::var_os("HOME").map(|home| PathBuf::from(home).join(".cache")))
        .unwrap_or_else(std::env::temp_dir);
    cache_dir.join("aktyn-quickshell").join("recent.json")
}

pub(crate) fn fuzzy_score(query: &str, candidate: &str) -> Option<f32> {
    let query = query.trim().to_lowercase();
    let candidate = candidate.to_lowercase();
    if query.is_empty() {
        return Some(1.0);
    }
    if let Some(index) = candidate.find(&query) {
        let offset_penalty = index as f32 / candidate.len().max(1) as f32;
        return Some(1.0 - offset_penalty * 0.2);
    }

    let query_chars = query.chars().collect::<Vec<_>>();
    let candidate_chars = candidate.chars().collect::<Vec<_>>();
    let mut previous = (0..=candidate_chars.len()).collect::<Vec<_>>();
    for (query_index, query_char) in query_chars.iter().enumerate() {
        let mut current = vec![query_index + 1; candidate_chars.len() + 1];
        for (candidate_index, candidate_char) in candidate_chars.iter().enumerate() {
            let substitution_cost = usize::from(query_char != candidate_char);
            current[candidate_index + 1] = (previous[candidate_index + 1] + 1)
                .min(current[candidate_index] + 1)
                .min(previous[candidate_index] + substitution_cost);
        }
        previous = current;
    }
    let width = query_chars.len().max(candidate_chars.len());
    if width == 0 {
        return Some(1.0);
    }
    let score = 1.0 - previous[candidate_chars.len()] as f32 / width as f32;
    (score >= 0.35).then_some(score)
}

#[cfg(test)]
mod tests {
    use super::fuzzy_score;

    #[test]
    fn fuzzy_search_matches_typo_and_prefix_queries() {
        assert!(fuzzy_score("firef", "Firefox Web Browser").unwrap() > 0.35);
        assert!(fuzzy_score("fire", "Firefox Web Browser").unwrap() > 0.8);
        assert!(fuzzy_score("zzzz", "Firefox Web Browser").is_none());
    }
}
