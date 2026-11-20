use std::process::Command;

#[derive(Clone, Debug)]
pub(crate) struct MediaPlayer {
    pub(crate) name: String,
    pub(crate) title: String,
}

pub(crate) fn read_media_players() -> Vec<MediaPlayer> {
    let output = match Command::new("playerctl").arg("-l").output() {
        Ok(output) if output.status.success() => output,
        Ok(_) => return Vec::new(),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Vec::new(),
        Err(error) => {
            eprintln!("Could not list MPRIS players: {error}");
            return Vec::new();
        }
    };

    String::from_utf8_lossy(&output.stdout)
        .lines()
        .filter(|name| !name.trim().is_empty())
        .map(|name| {
            let name = name.trim().to_owned();
            let metadata = Command::new("playerctl")
                .args([
                    "--player",
                    &name,
                    "metadata",
                    "--format",
                    "{{artist}} — {{title}}",
                ])
                .output();
            let title = match metadata {
                Ok(output) if output.status.success() => {
                    let title = String::from_utf8_lossy(&output.stdout).trim().to_owned();
                    if title.is_empty() {
                        name.clone()
                    } else {
                        title
                    }
                }
                Ok(_) => name.clone(),
                Err(error) => {
                    eprintln!("Could not read metadata for MPRIS player {name}: {error}");
                    name.clone()
                }
            };
            MediaPlayer { name, title }
        })
        .collect()
}

pub(crate) fn control_media_player(player: &str, action: &str) {
    let args = ["--player", player, action];
    if let Err(error) = Command::new("playerctl").args(args).spawn() {
        eprintln!("Could not run playerctl {action} for {player}: {error}");
    }
}
