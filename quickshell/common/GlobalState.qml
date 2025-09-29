pragma Singleton

import QtQuick
import Quickshell

Singleton {
  property QtObject bar: QtObject {
    property QtObject calendarPanel: QtObject {
      property bool open: false
      property ShellScreen screen: Quickshell.screens[0]
      property var requestFocus

      property QtObject timer: QtObject {
        property bool running: false
      }
    }
  }
}
