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

  component StopperState: QtObject {
    id: stopperRoot

    property bool running: false
    property bool paused: false

    property int elapsedSeconds: 0

    property Timer stopwatchTimer: Timer {
      interval: 1000
      repeat: true
      running: stopperRoot.running && !stopperRoot.paused
      onTriggered: {
        stopperRoot.elapsedSeconds++;
      }
    }
  }

  component CalendarPanelState: QtObject {
    property TimerState timer: TimerState {}
    property StopperState stopper: StopperState {}
  }

  component AppSearchState: QtObject {
    property int selectedEntryIndex: 0
  }

  component MainPanelState: PanelState {
    property bool superReleaseHelper: true
    property int mainPanelTabIndex: 0

    property int currentContentWidth: 128
    property int currentContentHeight: 128

    property AppSearchState appSearch: AppSearchState {}
    property bool settingsWindowOpen: false
  }

  component BarState: QtObject {
    property CalendarPanelState calendarPanel: CalendarPanelState {}

    property PanelState notesPanel: PanelState {}

    property PanelState notificationsPanel: PanelState {}

    property PanelState mediaControls: PanelState {}

    property MainPanelState mainPanel: MainPanelState {}
  }
  property BarState bar: BarState {}

  component OsdState: QtObject {
    property bool volumeOpen: false
    property bool clipboardPanelOpen: false
    property bool cheetsheetOpen: false
  }
  property OsdState osd: OsdState {}

  // --------------------------------------------------------------------------------

  GlobalShortcut {
    name: "overviewToggleRelease"
    description: "Toggles main panel"

    onPressed: {
      root.bar.mainPanel.superReleaseHelper = true;
    }

    onReleased: {
      if (!root.bar.mainPanel.superReleaseHelper) {
        root.bar.mainPanel.superReleaseHelper = true;
        return;
      }
      root.bar.mainPanel.open = !root.bar.mainPanel.open;
      if (root.bar.mainPanel.open) {
        root.bar.mainPanel.mainPanelTabIndex = 0;
      }
      if (!root.bar.mainPanel.open && typeof root.bar.mainPanel.requestFocus === 'function') {
        root.bar.mainPanel.requestFocus(false);
      }
    }
  }
  GlobalShortcut {
    name: "overviewToggleReleaseInterrupt"
    description: "Interrupts super release whenever shortcut consisting of super key has been pressed"

    onPressed: {
      root.bar.mainPanel.superReleaseHelper = false;
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
