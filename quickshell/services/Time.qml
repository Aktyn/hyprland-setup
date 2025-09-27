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
}
