use std::{
    io::Write,
    process::{Command, Stdio},
};

use crate::model::ClipboardEntry;

pub(crate) fn read_clipboard_history() -> Vec<ClipboardEntry> {
    let Ok(output) = Command::new("cliphist").arg("list").output() else {
        return Vec::new();
    };
    String::from_utf8_lossy(&output.stdout)
        .lines()
        .filter_map(|line| {
            let (id, text) = line.split_once('\t')?;
            Some(ClipboardEntry {
                id: id.trim().to_owned(),
                text: text.to_owned(),
            })
        })
        .collect()
}

pub(crate) fn copy_clipboard_entry(id: &str) {
    if id.is_empty() || !id.chars().all(|ch| ch.is_ascii_digit()) {
        eprintln!("Ignoring invalid clipboard entry identifier");
        return;
    }
    let decoded = match Command::new("cliphist").args(["decode", id]).output() {
        Ok(output) if output.status.success() => output.stdout,
        Ok(output) => {
            eprintln!("cliphist could not decode entry {id}: {}", output.status);
            return;
        }
        Err(error) => {
            eprintln!("Could not read clipboard entry {id}: {error}");
            return;
        }
    };
    let mut copy = match Command::new("wl-copy").stdin(Stdio::piped()).spawn() {
        Ok(child) => child,
        Err(error) => {
            eprintln!("Could not start wl-copy: {error}");
            return;
        }
    };
    if let Some(mut stdin) = copy.stdin.take() {
        if let Err(error) = stdin.write_all(&decoded) {
            eprintln!("Could not copy clipboard item: {error}");
            return;
        }
    }
    if let Err(error) = copy.wait() {
        eprintln!("wl-copy failed: {error}");
    }
}
