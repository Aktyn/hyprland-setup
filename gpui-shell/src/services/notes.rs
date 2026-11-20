use std::{fs, path::PathBuf, process::Command};

pub(crate) fn notes_path() -> PathBuf {
    std::env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(std::env::temp_dir)
        .join(".local/share/aktyn-shell/notes.txt")
}

pub(crate) fn open_notes() {
    let path = notes_path();
    if let Some(parent) = path.parent() {
        if let Err(error) = fs::create_dir_all(parent) {
            eprintln!("Could not create notes directory: {error}");
            return;
        }
    }
    if !path.exists() {
        if let Err(error) = fs::write(&path, "") {
            eprintln!("Could not create notes file: {error}");
            return;
        }
    }
    if let Err(error) = Command::new("xdg-open").arg(path).spawn() {
        eprintln!("Could not open notes: {error}");
    }
}
