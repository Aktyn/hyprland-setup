pragma Singleton

import Quickshell
import QtQuick

Singleton {
  readonly property string time: {
    Qt.formatDateTime(clock.date, "hh:mm • ddd, dd/MM");
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
