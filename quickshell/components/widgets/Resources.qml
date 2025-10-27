import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

import "../../common"
import "../../services"
import "./common"

StyledButton {
  Layout.alignment: Qt.AlignVCenter
  Layout.leftMargin: -Style.sizes.spacingMedium
  Layout.rightMargin: -Style.sizes.spacingMedium
  implicitWidth: rowLayout.width + Style.sizes.spacingMedium * 2
  implicitHeight: rowLayout.height + Style.sizes.spacingExtraSmall * 2

  RowLayout {
    id: rowLayout

    anchors.centerIn: parent
    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    Layout.minimumHeight: Style.sizes.iconLarge

    spacing: Style.sizes.spacingMedium

    Resource {
      iconName: "speed"
      percentage: ResourceUsage.cpuUsage
      shown: true
    }

    Resource {
      iconName: "memory"
      percentage: ResourceUsage.memoryUsedPercentage
    }

    Resource {
      iconName: "swap_horiz"
      percentage: ResourceUsage.swapUsedPercentage
      shown: percentage > 0
    }
  }

  onClicked: Hyprland.dispatch("exec [float] gnome-system-monitor")
}
