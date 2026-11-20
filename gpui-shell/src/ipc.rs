use std::{
    fs,
    io::{Read, Write},
    os::unix::net::{UnixListener, UnixStream},
    path::PathBuf,
};

use crate::model::PanelKind;

pub(crate) struct SocketGuard(PathBuf);

impl Drop for SocketGuard {
    fn drop(&mut self) {
        if let Err(error) = fs::remove_file(&self.0) {
            if error.kind() != std::io::ErrorKind::NotFound {
                eprintln!("Could not remove shell IPC socket: {error}");
            }
        }
    }
}

pub(crate) type Instance = (tokio::sync::mpsc::UnboundedReceiver<PanelKind>, SocketGuard);

pub(crate) fn acquire_instance(request: Option<PanelKind>) -> Result<Option<Instance>, String> {
    let socket_path = std::env::var_os("XDG_RUNTIME_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(std::env::temp_dir)
        .join("aktyn-shell.sock");

    if let Ok(mut stream) = UnixStream::connect(&socket_path) {
        if let Some(request) = request {
            stream
                .write_all(request.key().as_bytes())
                .map_err(|error| format!("could not contact the running shell: {error}"))?;
        }
        return Ok(None);
    }

    if socket_path.exists() {
        fs::remove_file(&socket_path)
            .map_err(|error| format!("could not remove stale IPC socket: {error}"))?;
    }
    let listener = UnixListener::bind(&socket_path)
        .map_err(|error| format!("could not create IPC socket: {error}"))?;
    let (sender, receiver) = tokio::sync::mpsc::unbounded_channel();

    std::thread::Builder::new()
        .name("aktyn-shell-ipc".into())
        .spawn(move || {
            for connection in listener.incoming() {
                let mut stream = match connection {
                    Ok(stream) => stream,
                    Err(error) => {
                        eprintln!("Shell IPC listener failed: {error}");
                        continue;
                    }
                };
                let mut message = String::new();
                if let Err(error) = stream.read_to_string(&mut message) {
                    eprintln!("Could not read shell IPC request: {error}");
                    continue;
                }
                if let Some(request) = PanelKind::from_key(message.trim()) {
                    if sender.send(request).is_err() {
                        break;
                    }
                } else {
                    eprintln!("Ignoring invalid shell IPC request");
                }
            }
        })
        .map_err(|error| format!("could not start IPC listener: {error}"))?;

    Ok(Some((receiver, SocketGuard(socket_path))))
}
