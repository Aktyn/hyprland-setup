pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

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

    property QtObject notesPanel: QtObject {
      property bool open: false
      property ShellScreen screen: Quickshell.screens[0]
      property var requestFocus
    }

    property QtObject notificationsPanel: QtObject {
      id: _notificationsPanel

      property bool open: false
      property ShellScreen screen: Quickshell.screens[0]
      property var requestFocus
    }

    property QtObject mediaControls: QtObject {
      property bool open: false
      property ShellScreen screen: Quickshell.screens[0]
      property var requestFocus
    }
  }

  property QtObject osd: QtObject {
    property bool volumeOpen: false
    property bool clipboardPanelOpen: false
  }

  property QtObject leftSidebar: QtObject {
    id: leftSidebar

    property bool open: false
    property ShellScreen screen: Quickshell.screens[0]
    property var requestFocus

    property QtObject appSearch: QtObject {
      property int selectedEntryIndex: 0
    }

    property bool superReleaseHelper: false
  }

  property QtObject rightSidebar: QtObject {
    id: rightSidebar

    property bool open: false
    property ShellScreen screen: Quickshell.screens[0]
    property var requestFocus
  }

  // --------------------------------------------------------------------------------

  GlobalShortcut {
    name: "overviewToggleRelease" //TODO: adjust name after migration
    description: "Toggles left sidebar"

    onPressed: {
      leftSidebar.superReleaseHelper = true;
    }

    onReleased: {
      if (!leftSidebar.superReleaseHelper) {
        leftSidebar.superReleaseHelper = true;
        return;
      }
      leftSidebar.open = !leftSidebar.open;
      if (!leftSidebar.open && typeof leftSidebar.requestFocus === 'function') {
        leftSidebar.requestFocus(false);
      }
    }
  }
  GlobalShortcut {
    name: "overviewToggleReleaseInterrupt"
    description: "Interrupts super release whenever shortcut consisting of super key has been pressed"

    onPressed: {
      leftSidebar.superReleaseHelper = false;
    }
  }
}
