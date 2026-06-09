pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import "."

Singleton {
  id: hyprlandSingleton

  property list<string> runningApps: Hyprland.toplevels.values.filter(app => app.wayland?.appId).map(app => app.wayland.appId.toLowerCase())

  property var windowList: []
  property var addresses: []
  property var windowByAddress: ({})
  property var monitors: []
  property var layers: ({})

  function hasFullScreen(screen: ShellScreen): bool {
    const monitor = Hyprland.monitorFor(screen);
    const workspace = monitor && monitor.activeWorkspace;
    const toplevels = workspace && workspace.toplevels;
    const values = toplevels && toplevels.values;

    if (!values || !values.some) {
      return false;
    }

    return values.some(function (top) {
      return top.wayland && top.wayland.fullscreen;
    });
  }

  function update() {
    getClients.running = true;
    getMonitors.running = true;
    getLayers.running = true;
  }

  Component.onCompleted: {
    update();
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      // Ignore some readonly events
      const readonlyEventNames = ["activewindow", "activewindowv2", "focusedmon", "focusedmonv2", "workspace", "workspacev2", "closelayer"];
      if (!readonlyEventNames.includes(event.name)) {
        console.log("Updating HyprlandInfo due to event:", event.name);
        hyprlandSingleton.update();
      }
    }
  }

  component GeneralType: QtObject {
    // top, right, bottom, left
    property var gapsIn: [0, 0, 0, 0]
    property var gapsOut: [0, 0, 0, 0]
  }

  readonly property GeneralType general: GeneralType {}

  component DecorationType: QtObject {
    property int rounding: 16
  }

  readonly property DecorationType decoration: DecorationType {}

  Process {
    id: getClients
    command: "hyprctl clients -j".split(" ")
    stdout: StdioCollector {
      id: clientsCollector
      onStreamFinished: {
        hyprlandSingleton.windowList = JSON.parse(clientsCollector.text);
        let tempWinByAddress = {};
        for (let i = 0; i < hyprlandSingleton.windowList.length; ++i) {
          const win = hyprlandSingleton.windowList[i];
          tempWinByAddress[win.address] = win;
        }
        hyprlandSingleton.windowByAddress = tempWinByAddress;
        hyprlandSingleton.addresses = hyprlandSingleton.windowList.map(win => win.address);
      }
    }
  }
  Process {
    id: getMonitors
    command: "hyprctl monitors -j".split(" ")
    stdout: StdioCollector {
      onStreamFinished: {
        hyprlandSingleton.monitors = JSON.parse(this.text);

        if (Config.bar.screenList.length === 0 && Array.isArray(Hyprland.monitors) && Hyprland.monitors.length > 0) {
          Config.bar.screenList = Hyprland.monitors?.map(m => m.name) || [];
        }
      }
    }
  }

  Process {
    id: getLayers
    command: ["hyprctl", "layers", "-j"]
    stdout: StdioCollector {
      id: layersCollector
      onStreamFinished: {
        hyprlandSingleton.layers = JSON.parse(layersCollector.text);
      }
    }
  }

  function auditJsonStructure(json, expectedKeys) {
    const keys = Object.keys(json);
    for (const key of expectedKeys) {
      if (!keys.includes(key)) {
        console.warn("Unexpected JSON structure: " + JSON.stringify(json), '\nmissing key: "' + key + '"');
        return false;
      }
    }
    return true;
  }

  Process {
    command: "hyprctl getoption decoration:rounding -j".split(" ")
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const json = JSON.parse(this.text);
        if (hyprlandSingleton.auditJsonStructure(json, ["int"])) {
          hyprlandSingleton.decoration.rounding = Math.max(0, Number(json.int));
        }
      }
    }
  }
  Process {
    command: "hyprctl getoption general:gaps_in -j".split(" ")
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const json = JSON.parse(this.text);
        if (hyprlandSingleton.auditJsonStructure(json, ["css"])) {
          hyprlandSingleton.general.gapsIn = json.css?.split(" ").map(v => Number(v)) || [0, 0, 0, 0];
        }
      }
    }
  }
  Process {
    command: "hyprctl getoption general:gaps_out -j".split(" ")
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const json = JSON.parse(this.text);
        if (hyprlandSingleton.auditJsonStructure(json, ["css"])) {
          hyprlandSingleton.general.gapsOut = json.css?.split(" ").map(v => Number(v)) || [0, 0, 0, 0];
        }
      }
    }
  }
}
