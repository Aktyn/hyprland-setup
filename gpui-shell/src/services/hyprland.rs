use std::process::Command;

pub(crate) fn read_shortcuts() -> Vec<(String, String)> {
    let Ok(output) = Command::new("hyprctl").args(["binds", "-j"]).output() else {
        return Vec::new();
    };
    let Ok(bindings) = serde_json::from_slice::<Vec<serde_json::Value>>(&output.stdout) else {
        return Vec::new();
    };
    let mut shortcuts = bindings
        .iter()
        .filter_map(|binding| {
            if binding["mouse"].as_bool().unwrap_or(false)
                || !binding["has_description"].as_bool().unwrap_or(false)
            {
                return None;
            }
            let description = binding["description"].as_str()?.trim();
            if description.is_empty() {
                return None;
            }
            let key = binding["key"].as_str()?.replace("_L", "").replace("_R", "");
            let mask = binding["modmask"].as_u64().unwrap_or_default();
            let mut keys = Vec::new();
            for (bit, name) in [(64, "SUPER"), (4, "CTRL"), (8, "ALT"), (1, "SHIFT")] {
                if mask & bit != 0 {
                    keys.push(name);
                }
            }
            if !keys.iter().any(|modifier| *modifier == key) && !key.is_empty() {
                keys.push(&key);
            }
            Some((keys.join(" + "), description.to_owned()))
        })
        .collect::<Vec<_>>();
    shortcuts.sort_by(|left, right| left.1.cmp(&right.1));
    shortcuts
}

pub(crate) fn dispatch(args: &[&str]) {
    if let Err(error) = Command::new("hyprctl").args(args).spawn() {
        eprintln!("Could not run hyprctl: {error}");
    }
}
