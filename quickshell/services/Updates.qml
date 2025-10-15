pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

import "../common"

Singleton {
  id: root

  property int updatesCount: 0
  property bool hasUpdates: this.updatesCount > 0
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

  // ------------------------------------------------------

  property bool isUpdating: updateProcess.running
  property string lastUpdateOutput: updateStdout.text

  Process {
    id: updateProcess
    //TODO: second update pass (sudo yay -Syu --noconfirm), only if yay is available
    command: ["bash", "-c", "sudo pacman -Syu --noconfirm"]
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

  property var update: function () {
    console.log("Starting system update...");
    updateProcess.running = true;
  }
}
