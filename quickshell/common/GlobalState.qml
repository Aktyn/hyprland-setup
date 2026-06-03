pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

import "."
import "../services"

Singleton {
  id: root

  property bool transparencyEnabled: Config.general.panelsTransparency < 1
  property color backgroundColor: this.transparencyEnabled ? Colors.transparentize(Style.colors.surface, Config.general.panelsTransparency) : Style.colors.surface

  component TimerState: QtObject {
    id: timerRoot

    property bool running: false
    property bool paused: false

    property int remainingSeconds: 0

    property Timer countdownTimer: Timer {
      interval: 1000
      repeat: true
      running: timerRoot.running && !timerRoot.paused
      onTriggered: {
        if (timerRoot.remainingSeconds > 0) {
          timerRoot.remainingSeconds--;
        } else {
          this.running = false;
          timerRoot.running = false;
          timerRoot.paused = false;
          timerRoot.remainingSeconds = 0;

          Quickshell.execDetached(["notify-send", "Timer finished!", "--urgency", "CRITICAL", "--transient", "--icon", Quickshell.shellPath("assets/icons/timer-alert.svg")]);
        }
      }
    }
  }

  component PanelState: QtObject {
    property bool open: false
    property ShellScreen screen: Quickshell.screens[0]
    property var requestFocus
  }

  component CalendarPanelState: PanelState {
    property TimerState timer: TimerState {}
  }

  component BarState: QtObject {
    property CalendarPanelState calendarPanel: CalendarPanelState {}

    property PanelState notesPanel: PanelState {}

    property PanelState notificationsPanel: PanelState {}

    property PanelState mediaControls: PanelState {}
  }

  readonly property BarState bar: BarState {}

  component OsdState: QtObject {
    property bool volumeOpen: false
    property bool clipboardPanelOpen: false
    property bool cheetsheetOpen: false
  }

  readonly property OsdState osd: OsdState {}

  component AppSearchState: QtObject {
    property int selectedEntryIndex: 0
  }

  component LeftSidebarState: QtObject {
    property bool open: false
    property ShellScreen screen: Quickshell.screens[0]
    property var requestFocus

    property AppSearchState appSearch: AppSearchState {}

    property bool superReleaseHelper: true
  }

  readonly property LeftSidebarState leftSidebar: LeftSidebarState {}

  component RightSidebarState: QtObject {
    property bool open: false
    property ShellScreen screen: Quickshell.screens[0]
    property var requestFocus

    property bool settingsWindowOpen: false
  }

  readonly property RightSidebarState rightSidebar: RightSidebarState {}

  // --------------------------------------------------------------------------------

  GlobalShortcut {
    name: "overviewToggleRelease"
    description: "Toggles left sidebar"

    onPressed: {
      root.leftSidebar.superReleaseHelper = true;
    }

    onReleased: {
      if (!root.leftSidebar.superReleaseHelper) {
        root.leftSidebar.superReleaseHelper = true;
        return;
      }
      root.leftSidebar.open = !root.leftSidebar.open;
      if (!root.leftSidebar.open && typeof root.leftSidebar.requestFocus === 'function') {
        root.leftSidebar.requestFocus(false);
      }
    }
  }
  GlobalShortcut {
    name: "overviewToggleReleaseInterrupt"
    description: "Interrupts super release whenever shortcut consisting of super key has been pressed"

    onPressed: {
      root.leftSidebar.superReleaseHelper = false;
    }
  }

  GlobalShortcut {
    name: "overviewClipboardToggle"
    description: "Toggle clipboard query on overview widget"

    onPressed: {
      root.osd.clipboardPanelOpen = !root.osd.clipboardPanelOpen;
    }
  }

  GlobalShortcut {
    name: "osdCheetsheetToggle"
    description: "Toggles cheetsheet OSD on press"

    onPressed: {
      root.osd.cheetsheetOpen = !root.osd.cheetsheetOpen;
    }
  }
}
