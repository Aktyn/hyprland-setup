pragma Singleton

import QtQuick
import Quickshell

import "../services"

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

    property QtObject notificationsPanel: QtObject {
      id: _notificationsPanel

      property bool open: false
      property ShellScreen screen: Quickshell.screens[0]
      property var requestFocus

      // property Timer newNotificationAutoHide: Timer {
      //   running: false
      //   repeat: false

      //   onTriggered: {
      //     _notificationsPanel.open = false;
      //   }
      // }
    }
  }
}
