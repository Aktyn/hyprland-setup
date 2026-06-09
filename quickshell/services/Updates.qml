pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

import "../common"

Singleton {
  id: root

  property int updatesCount: 0
  property bool hasUpdates: this.updatesCount > 0
  property bool commitOutdated: false
  property bool hasYay: false

  Process {
    id: updatesChecker
    running: true
    command: ["bash", "-c", "checkupdates | wc -l"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.updatesCount = parseInt(this.text) || 0;
        if (root.updatesCount > 0) {
          console.info("Updates available: " + root.updatesCount);
        }
      }
    }
  }

  Timer {
    id: updatesCheckInterval
    interval: Config.general.updatesCheckInterval ?? 60 * 60 * 1000
    running: true
    repeat: true
    onTriggered: {
      updatesChecker.running = true;
    }
  }

  Process {
    id: yayChecker
    running: true
    command: ["bash", "-c", "command -v yay"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.hasYay = this.text.trim().length > 0;
      }
    }
  }

  Process {
    id: commitChecker
    running: true
    command: ["bash", "-c", "git ls-remote https://github.com/Aktyn/hyprland-setup.git HEAD | awk '{printf $1}'"]
    stdout: StdioCollector {
      onStreamFinished: {
        if(this.text.trim() !== Config.commitHash) {
          root.commitOutdated = true;
        }
      }
    }
  }

  // ------------------------------------------------------

  property bool isUpdating: updateProcess.running

  Process {
    id: updateProcess
    command: ["kitty", "--hold", "fish", "-c", `sudo pacman -Syu --noconfirm${root.hasYay ? " && yay -Syu --noconfirm" : ""}`]
    running: false

    stdout: StdioCollector {
      id: updateStdout

      waitForEnd: false
      onStreamFinished: {
        console.log("Update finished.");
        root.updatesCount = 0;
        updatesChecker.running = true; //recheck for updates
      }
    }
  }

  Process {
    id: updateShellProcess
    command: ["kitty", "--hold", "fish", "-c", `curl -Ls https://raw.githubusercontent.com/Aktyn/hyprland-setup/main/install.sh | bash`]
    running: false

    stdout: StdioCollector {
      waitForEnd: false
      onStreamFinished: {
        console.log("Shell update finished.");
      }
    }
  }
  property var update: function () {
    console.info("Starting system update...");
    updateProcess.running = true;
    GlobalState.bar.mainPanel.open = false;
  }

  property var updateShell: function() {
    console.info("Updating shell")
    updateShellProcess.running = true;
    GlobalState.bar.mainPanel.open = false;
  }
}
