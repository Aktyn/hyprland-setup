pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../common"

Singleton {
  id: root
  property var manualActive
  property int colorTemperature: 4000 //TODO: add to config
  property bool firstEvaluation: true
  property bool active: false

  function enable() {
    root.active = true;
    console.log("Enabling hyprsunset");
    Quickshell.execDetached(["bash", "-c", `pidof hyprsunset || hyprsunset --temperature ${root.colorTemperature}`]);
  }

  function disable() {
    root.active = false;
    console.log("Disabling hyprsunset");
    Quickshell.execDetached(["bash", "-c", "pkill hyprsunset"]);
  }

  function fetchState() {
    fetchProc.running = true;
  }

  Process {
    id: fetchProc
    running: true
    command: ["bash", "-c", "hyprctl hyprsunset temperature"]
    stdout: StdioCollector {
      id: stateCollector
      onStreamFinished: {
        const output = stateCollector.text.trim();
        if (!output.length || output.startsWith("Couldn't"))
          root.active = false;
        else
          root.active = (output != "6500");
      }
    }
  }

  function toggle() {
    if (root.manualActive === undefined) {
      root.manualActive = root.active;
    }

    root.manualActive = !root.manualActive;
    if (root.manualActive) {
      root.enable();
    } else {
      root.disable();
    }
  }
}
