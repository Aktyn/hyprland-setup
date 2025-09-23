import Quickshell
import Quickshell.Io
import QtQuick

PanelWindow {
  height: 32
  // aboveWindows: false
  // exclusionMode: ExclusionMode.Auto

  anchors {
    top: true
    left: true
    right: true
  }

  color: "#456"

  Text {
    id: clock

    anchors.centerIn: parent
    text: "---"
    color: "#fff"

    Process {
      id: dateProc

      command: ["date", "+%d-%m-%Y %H:%M"]
      running: false
      stdout: StdioCollector {
        onStreamFinished: clock.text = this.text
      }
    }

    Timer {
      interval: 1000 //TODO: align to system clock seconds for better accuracy
      running: true
      repeat: true
      onTriggered: dateProc.running = true
    }
  }
}
