use std::process::Command;

use crate::services::run_detached;

pub(crate) fn toggle_night_light() {
    match Command::new("hyprctl")
        .args(["hyprsunset", "temperature"])
        .output()
    {
        Ok(output) => {
            let temperature = String::from_utf8_lossy(&output.stdout).trim().to_owned();
            if !temperature.is_empty()
                && !temperature.starts_with("Couldn't")
                && temperature != "6500"
            {
                run_detached("pkill", &["hyprsunset"]);
                return;
            }

            if let Err(error) = Command::new("hyprsunset")
                .args(["--temperature", "4000"])
                .spawn()
            {
                eprintln!("Could not enable night light: {error}");
            }
        }
        Err(error) => eprintln!("Could not query night-light state: {error}"),
    }
}

pub(crate) fn toggle_bluetooth(enabled: bool) {
    std::thread::spawn(move || {
        let rfkill = Command::new("rfkill")
            .args([if enabled { "unblock" } else { "block" }, "bluetooth"])
            .status();
        match rfkill {
            Ok(status) if status.success() => {}
            Ok(status) => eprintln!("Could not update Bluetooth radio state: {status}"),
            Err(error) => eprintln!("Could not update Bluetooth radio state: {error}"),
        }
        match Command::new("bluetoothctl")
            .args(["power", if enabled { "on" } else { "off" }])
            .status()
        {
            Ok(status) if status.success() => {}
            Ok(status) => eprintln!("Could not update Bluetooth power state: {status}"),
            Err(error) => eprintln!("Could not update Bluetooth power state: {error}"),
        }
    });
}

pub(crate) fn suspend_system() {
    std::thread::spawn(|| match Command::new("systemctl").arg("suspend").status() {
        Ok(status) if status.success() => {}
        Ok(_) => run_detached("loginctl", &["suspend"]),
        Err(error) => {
            eprintln!("Could not run systemctl suspend: {error}");
            run_detached("loginctl", &["suspend"]);
        }
    });
}
