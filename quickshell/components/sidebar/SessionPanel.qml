import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

import "../../common"

import "../widgets"

GridLayout {
  id: sessionButtonsLayout

  rows: 1
  columns: 3
  columnSpacing: Style.sizes.spacingMedium

  uniformCellWidths: true
  uniformCellHeights: true

  function closeAllWindows() {
    for (const topLevel of Hyprland.toplevels.values) {
      topLevel.wayland?.close();
    }
  }

  SessionButton {
    Layout.fillWidth: true

    iconName: "power_settings_new"
    buttonText: "Shutdown"

    onClicked: {
      sessionButtonsLayout.closeAllWindows();
      Quickshell.execDetached(["bash", "-c", `systemctl poweroff || loginctl poweroff`]);
    }
  }
  SessionButton {
    Layout.fillWidth: true

    iconName: "restart_alt"
    buttonText: "Reboot"

    onClicked: {
      sessionButtonsLayout.closeAllWindows();
      Quickshell.execDetached(["bash", "-c", `reboot || loginctl reboot`]);
    }
  }
  SessionButton {
    Layout.fillWidth: true

    iconName: "lock"
    buttonText: "Lock"

    onClicked: {
      Quickshell.execDetached(["loginctl", "lock-session"]);
      GlobalState.rightSidebar.open = false;
      GlobalState.rightSidebar.requestFocus?.(false);
    }
  }
}
