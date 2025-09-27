pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
  id: hyprlandSingleton

  property var windowList: []
  property var addresses: []
  property var windowByAddress: ({})
  property var monitors: []
  property var workspaces: []
  property var workspaceIds: []
  property var workspaceById: ({})
  property var activeWorkspace: null
  property var layers: ({})

  function update() {
    getClients.running = true;
    getMonitors.running = true;
    getLayers.running = true;

    getWorkspaces.running = true;
    getActiveWorkspace.running = true;
  }

  Component.onCompleted: {
    update();
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      // console.info("Hyprland raw event name:", event.name);
      update();
    }
  }

  property QtObject general: QtObject {
    // top, right, bottom, left
    property var gapsIn: [0, 0, 0, 0]
    property var gapsOut: [0, 0, 0, 0]
  }

  property QtObject decoration: QtObject {
    property int rounding: 16
  }

  Process {
    id: getClients
    command: "hyprctl clients -j".split(" ")
    stdout: StdioCollector {
      id: clientsCollector
      onStreamFinished: {
        hyprlandSingleton.windowList = JSON.parse(clientsCollector.text);
        let tempWinByAddress = {};
        for (var i = 0; i < hyprlandSingleton.windowList.length; ++i) {
          var win = hyprlandSingleton.windowList[i];
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

        if (Config.bar.screenList.length === 0 && Hyprland.monitors.length > 0) {
          Config.bar.screenList = Hyprland.monitors.map(m => m.name);
        }
      }
    }
  }

  Process {
    id: getWorkspaces
    command: ["hyprctl", "workspaces", "-j"]
    stdout: StdioCollector {
      id: workspacesCollector
      onStreamFinished: {
        hyprlandSingleton.workspaces = JSON.parse(workspacesCollector.text);
        let tempWorkspaceById = {};
        for (var i = 0; i < hyprlandSingleton.workspaces.length; ++i) {
          var ws = hyprlandSingleton.workspaces[i];
          tempWorkspaceById[ws.id] = ws;
        }
        hyprlandSingleton.workspaceById = tempWorkspaceById;
        hyprlandSingleton.workspaceIds = hyprlandSingleton.workspaces.map(ws => ws.id);
      }
    }
  }

  Process {
    id: getActiveWorkspace
    command: "hyprctl activeworkspace -j".split(" ")
    stdout: StdioCollector {
      id: activeWorkspaceCollector
      onStreamFinished: {
        hyprlandSingleton.activeWorkspace = JSON.parse(activeWorkspaceCollector.text);
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

  function biggestWindowForWorkspace(workspaceId) {
    const windowsInThisWorkspace = hyprlandSingleton.windowList.filter(w => w.workspace.id == workspaceId);
    return windowsInThisWorkspace.reduce((maxWin, win) => {
                                           const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
                                           const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
                                           return winArea > maxArea ? win : maxWin;
                                         }, null);
  }

  Process {
    command: "hyprctl getoption decoration:rounding -j".split(" ")
    running: true
    stdout: StdioCollector {
      onStreamFinished: Number(hyprlandSingleton.decoration.rounding = JSON.parse(this.text).int)
    }
  }
  Process {
    command: "hyprctl getoption general:gaps_in -j".split(" ")
    running: true
    stdout: StdioCollector {
      onStreamFinished: hyprlandSingleton.general.gapsIn = JSON.parse(this.text).custom.split(" ").map(v => Number(v))
    }
  }
  Process {
    command: "hyprctl getoption general:gaps_out -j".split(" ")
    running: true
    stdout: StdioCollector {
      onStreamFinished: hyprlandSingleton.general.gapsOut = JSON.parse(this.text).custom.split(" ").map(v => Number(v))
    }
  }
}
