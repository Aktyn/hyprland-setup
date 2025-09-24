pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  readonly property string time: {
    Qt.formatDateTime(clock.date, "hh:mm • ddd, d/MM")
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  // Process {
  //   id: dateProc
  //   command: ["date", "+%d-%m-%Y %H:%M:%S"]
  //   running: true

  //   stdout: StdioCollector {
  //     onStreamFinished: timeSingleton.time = this.text
  //   }
  // }

  // Timer {
  //   interval: 1000
  //   running: true
  //   repeat: true
  //   onTriggered: dateProc.running = true
  // }
}