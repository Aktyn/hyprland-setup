use std::{
    collections::VecDeque,
    fs,
    process::Command,
    sync::{Mutex, OnceLock},
    time::Instant,
};

use crate::model::Status;

#[derive(Default)]
struct SampleState {
    cpu: Option<(u64, u64)>,
    network: Option<(Instant, u64, u64)>,
    download_history: VecDeque<u64>,
    upload_history: VecDeque<u64>,
}

static SAMPLE_STATE: OnceLock<Mutex<SampleState>> = OnceLock::new();

pub(crate) fn read_status() -> Status {
    let active_window_info = Command::new("hyprctl")
        .args(["activewindow", "-j"])
        .output()
        .ok()
        .and_then(|output| serde_json::from_slice::<serde_json::Value>(&output.stdout).ok());
    let active_window_app_id = active_window_info
        .as_ref()
        .and_then(|value| value["class"].as_str())
        .filter(|value| !value.is_empty())
        .unwrap_or("Desktop")
        .to_owned();
    let active_window_title = active_window_info
        .as_ref()
        .and_then(|value| value["title"].as_str())
        .filter(|value| !value.is_empty())
        .map(str::to_owned);
    let night_light_enabled = Command::new("hyprctl")
        .args(["hyprsunset", "temperature"])
        .output()
        .ok()
        .map(|output| String::from_utf8_lossy(&output.stdout).trim().to_owned())
        .is_some_and(|temperature| {
            !temperature.is_empty() && !temperature.starts_with("Couldn't") && temperature != "6500"
        });
    let workspace = Command::new("hyprctl")
        .args(["activeworkspace", "-j"])
        .output()
        .ok()
        .and_then(|output| serde_json::from_slice::<serde_json::Value>(&output.stdout).ok())
        .and_then(|value| value["id"].as_i64())
        .and_then(|id| i32::try_from(id).ok());
    let active_window =
        active_window_title.unwrap_or_else(|| format!("Workspace {}", workspace.unwrap_or(1)));
    let occupied_workspaces = Command::new("hyprctl")
        .args(["workspaces", "-j"])
        .output()
        .ok()
        .and_then(|output| serde_json::from_slice::<Vec<serde_json::Value>>(&output.stdout).ok())
        .map(|workspaces| {
            workspaces
                .iter()
                .filter_map(|workspace| workspace["id"].as_i64())
                .filter_map(|id| i32::try_from(id).ok())
                .collect()
        })
        .unwrap_or_default();
    let workspace_app_classes = Command::new("hyprctl")
        .args(["clients", "-j"])
        .output()
        .ok()
        .and_then(|output| serde_json::from_slice::<Vec<serde_json::Value>>(&output.stdout).ok())
        .map(|clients| parse_workspace_app_classes(&clients))
        .unwrap_or_default();
    let (battery, battery_charging) = battery_status();
    let meminfo = fs::read_to_string("/proc/meminfo").unwrap_or_default();
    let memory = memory_percent(&meminfo, "MemTotal:", "MemAvailable:");
    let swap = memory_percent(&meminfo, "SwapTotal:", "SwapFree:");
    let (cpu, download_bps, upload_bps) = sample_usage();
    let audio_status = Command::new("wpctl")
        .args(["get-volume", "@DEFAULT_AUDIO_SINK@"])
        .output()
        .ok()
        .and_then(|output| {
            let text = String::from_utf8_lossy(&output.stdout);
            let volume = text
                .split_whitespace()
                .nth(1)?
                .parse::<f32>()
                .ok()
                .map(|level| (level * 100.).round() as u8)?;
            Some((volume, text.contains("[MUTED]")))
        });
    let (volume, muted) = audio_status.unwrap_or((0, false));
    let media = Command::new("playerctl")
        .args(["metadata", "--format", "{{artist}} — {{title}}"])
        .output()
        .ok()
        .and_then(|output| {
            let title = String::from_utf8_lossy(&output.stdout).trim().to_owned();
            (!title.is_empty()).then_some(title)
        });
    let bluetooth_enabled = Command::new("bluetoothctl")
        .args(["show"])
        .output()
        .ok()
        .is_some_and(|output| String::from_utf8_lossy(&output.stdout).contains("Powered: yes"));
    let bluetooth_connected = Command::new("bluetoothctl")
        .args(["devices", "Connected"])
        .output()
        .ok()
        .and_then(|output| {
            String::from_utf8_lossy(&output.stdout)
                .lines()
                .find_map(|line| {
                    let mut fields = line.split_whitespace();
                    (fields.next()? == "Device").then(|| {
                        let _address = fields.next()?;
                        let name = fields.collect::<Vec<_>>().join(" ");
                        (!name.is_empty()).then_some(name)
                    })?
                })
        })
        .is_some();

    Status {
        active_window_app_id,
        active_window,
        night_light_enabled,
        workspace,
        occupied_workspaces,
        workspace_app_classes,
        battery,
        battery_charging,
        cpu,
        memory,
        swap,
        download_bps,
        upload_bps,
        volume: (audio_status.is_some()).then_some(volume),
        muted,
        media,
        bluetooth_enabled,
        bluetooth_connected,
    }
}

fn parse_workspace_app_classes(
    clients: &[serde_json::Value],
) -> std::collections::HashMap<i32, Vec<String>> {
    let mut workspaces = std::collections::HashMap::<i32, Vec<String>>::new();
    for client in clients {
        if client["xwayland"].as_bool() == Some(true) {
            continue;
        }
        let Some(workspace_id) = client["workspace"]["id"]
            .as_i64()
            .and_then(|id| i32::try_from(id).ok())
        else {
            continue;
        };
        let Some(class) = client["class"]
            .as_str()
            .or_else(|| client["initialClass"].as_str())
            .filter(|class| !class.is_empty())
        else {
            continue;
        };
        workspaces
            .entry(workspace_id)
            .or_default()
            .push(class.to_owned());
    }
    workspaces
}

fn battery_status() -> (Option<u8>, bool) {
    let Ok(entries) = fs::read_dir("/sys/class/power_supply") else {
        return (None, false);
    };
    for entry in entries.flatten() {
        let path = entry.path();
        let Ok(kind) = fs::read_to_string(path.join("type")) else {
            continue;
        };
        if kind.trim() != "Battery" {
            continue;
        }
        let capacity = fs::read_to_string(path.join("capacity"))
            .ok()
            .and_then(|value| value.trim().parse::<u8>().ok());
        let charging = fs::read_to_string(path.join("status"))
            .is_ok_and(|value| matches!(value.trim(), "Charging" | "Pending charge"));
        return (capacity, charging);
    }
    (None, false)
}

fn memory_percent(info: &str, total_key: &str, available_key: &str) -> Option<u8> {
    let value = |key: &str| {
        info.lines()
            .find(|line| line.starts_with(key))?
            .split_whitespace()
            .nth(1)?
            .parse::<u64>()
            .ok()
    };
    let total = value(total_key)?;
    let available = value(available_key)?;
    (total > 0).then_some((total.saturating_sub(available).saturating_mul(100) / total) as u8)
}

fn cpu_counters(stat: &str) -> Option<(u64, u64)> {
    let cpu = stat.lines().find(|line| line.starts_with("cpu "))?;
    let values = cpu
        .split_whitespace()
        .skip(1)
        .map(str::parse::<u64>)
        .collect::<Result<Vec<_>, _>>()
        .ok()?;
    if values.len() < 5 {
        return None;
    }
    let total = values.iter().sum();
    let idle = values[3].saturating_add(values.get(4).copied().unwrap_or_default());
    Some((total, idle))
}

fn default_network_counters(route: &str, devices: &str) -> Option<(u64, u64)> {
    let interface = route
        .lines()
        .skip(1)
        .filter_map(|line| {
            let fields = line.split_whitespace().collect::<Vec<_>>();
            if fields.len() <= 6 || fields[1] != "00000000" {
                return None;
            }
            Some((fields[0], fields[6].parse::<u64>().ok()?))
        })
        .min_by_key(|(_, metric)| *metric)
        .map(|(interface, _)| interface)?;
    devices.lines().find_map(|line| {
        let (name, counters) = line.split_once(':')?;
        if name.trim() != interface {
            return None;
        }
        let fields = counters
            .split_whitespace()
            .map(str::parse::<u64>)
            .collect::<Result<Vec<_>, _>>()
            .ok()?;
        (fields.len() >= 9).then_some((fields[0], fields[8]))
    })
}

fn sample_usage() -> (Option<u8>, Option<u64>, Option<u64>) {
    let cpu_now = fs::read_to_string("/proc/stat")
        .ok()
        .and_then(|stat| cpu_counters(&stat));
    let network_now = fs::read_to_string("/proc/net/route")
        .ok()
        .zip(fs::read_to_string("/proc/net/dev").ok())
        .and_then(|(route, devices)| default_network_counters(&route, &devices));
    let state = SAMPLE_STATE.get_or_init(|| Mutex::new(SampleState::default()));
    let Ok(mut state) = state.lock() else {
        eprintln!("System usage sampler lock is poisoned");
        return (None, None, None);
    };
    let cpu = cpu_now.and_then(|(total, idle)| {
        let previous = state.cpu.replace((total, idle))?;
        let total_delta = total.saturating_sub(previous.0);
        let idle_delta = idle.saturating_sub(previous.1);
        (total_delta > 0)
            .then_some((total_delta.saturating_sub(idle_delta) * 100 / total_delta) as u8)
    });
    let now = Instant::now();
    let rates = network_now.and_then(|(received, sent)| {
        let (previous_time, previous_received, previous_sent) =
            state.network.replace((now, received, sent))?;
        let elapsed = now.duration_since(previous_time).as_secs_f64();
        (elapsed > 0.).then(|| {
            (
                (received.saturating_sub(previous_received) as f64 / elapsed) as u64,
                (sent.saturating_sub(previous_sent) as f64 / elapsed) as u64,
            )
        })
    });
    if let Some((download, upload)) = rates {
        push_sample(&mut state.download_history, download);
        push_sample(&mut state.upload_history, upload);
    }
    let average = |samples: &VecDeque<u64>| {
        (!samples.is_empty()).then(|| {
            let (total, total_weight) = samples.iter().enumerate().fold(
                (0u128, 0u128),
                |(sum, total_weight), (index, value)| {
                    let weight = index as u128 + 1;
                    (sum + *value as u128 * weight, total_weight + weight)
                },
            );
            (total / total_weight.max(1)) as u64
        })
    };
    (
        cpu,
        average(&state.download_history),
        average(&state.upload_history),
    )
}

fn push_sample(history: &mut VecDeque<u64>, sample: u64) {
    history.push_back(sample);
    if history.len() > 10 {
        history.pop_front();
    }
}

#[cfg(test)]
mod tests {
    use super::{
        cpu_counters, default_network_counters, memory_percent, parse_workspace_app_classes,
    };

    #[test]
    fn computes_memory_and_cpu_usage_from_proc_files() {
        assert_eq!(
            memory_percent(
                "MemTotal: 100 kB\nMemAvailable: 25 kB",
                "MemTotal:",
                "MemAvailable:"
            ),
            Some(75)
        );
        assert_eq!(
            cpu_counters("cpu  10 2 3 80 5 0 0 0\ncpu0 1 1 1 1 0 0 0 0"),
            Some((100, 85))
        );
    }

    #[test]
    fn selects_default_interface_counters() {
        let routes = "Iface Destination Gateway Flags RefCnt Use Metric Mask\neth0 00000000 0 0003 0 0 10 0\n";
        let devices = "Inter-| Receive | Transmit\n face |bytes packets errs drop fifo frame compressed multicast|bytes packets errs drop fifo colls carrier compressed\n  eth0: 100 1 0 0 0 0 0 0 200 1 0 0 0 0 0 0\n";
        assert_eq!(default_network_counters(routes, devices), Some((100, 200)));
    }

    #[test]
    fn groups_wayland_clients_by_workspace() {
        let clients = [
            serde_json::json!({
                "workspace": {"id": 2},
                "class": "Firefox",
                "xwayland": false
            }),
            serde_json::json!({
                "workspace": {"id": 2},
                "initialClass": "Code",
                "xwayland": false
            }),
            serde_json::json!({
                "workspace": {"id": 3},
                "class": "LegacyApp",
                "xwayland": true
            }),
        ];
        let workspaces = parse_workspace_app_classes(&clients);
        assert_eq!(
            workspaces.get(&2),
            Some(&vec!["Firefox".to_owned(), "Code".to_owned()])
        );
        assert!(!workspaces.contains_key(&3));
    }
}
