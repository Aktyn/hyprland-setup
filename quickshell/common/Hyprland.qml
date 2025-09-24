pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: hyprlandSingleton

    property var monitors: []

    property QtObject general: QtObject {
        // top, right, bottom, left
        property var gapsIn: [0, 0, 0, 0]
        property var gapsOut: [0, 0, 0, 0]
    }

    property QtObject decoration: QtObject {
        property int rounding: 16
    }

    Process {
        command: "hyprctl monitors -j".split(" ")
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                hyprlandSingleton.monitors = JSON.parse(this.text)
            }
        }
    }

    Process {
        command: "hyprctl getoption decoration:rounding -j".split(" ")
        running: true
        stdout: StdioCollector {
            onStreamFinished: Number(
                                  hyprlandSingleton.decoration.rounding = JSON.parse(
                                      this.text).int)
        }
    }
    Process {
        command: "hyprctl getoption general:gaps_in -j".split(" ")
        running: true
        stdout: StdioCollector {
            onStreamFinished: hyprlandSingleton.general.gapsIn = JSON.parse(
                                  this.text).custom.split(" ").map(
                                  v => Number(v))
        }
    }
    Process {
        command: "hyprctl getoption general:gaps_out -j".split(" ")
        running: true
        stdout: StdioCollector {
            onStreamFinished: hyprlandSingleton.general.gapsOut = JSON.parse(
                                  this.text).custom.split(" ").map(
                                  v => Number(v))
        }
    }
}
