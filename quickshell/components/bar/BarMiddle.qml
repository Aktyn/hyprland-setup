import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../common"
import "../../services"

import "../widgets"
import "../widgets/common"

Item {
  id: section
  required property ShellScreen screen

  height: parent.height
  implicitWidth: middleContent.implicitWidth

  RowLayout {
    id: middleContent
    anchors.centerIn: parent
    spacing: Style.sizes.spacingLarge

    VSeparator {
      Layout.leftMargin: Style.sizes.spacingLarge
    }

    StyledButton {
      id: clockWidgetButton

      Layout.alignment: Qt.AlignVCenter
      Layout.leftMargin: -Style.sizes.spacingMedium
      Layout.rightMargin: -Style.sizes.spacingMedium
      implicitWidth: clockWidget.width + Style.sizes.spacingMedium * 2
      implicitHeight: clockWidget.height + Style.sizes.spacingExtraSmall * 2

      toggled: GlobalState.bar.calendarPanel.open

      ClockWidget {
        id: clockWidget
        anchors.centerIn: parent
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        color: Time.time.startsWith("13:37") ? Style.colors.primary : Style.colors.colorOnSurface
      }

      onPressed: {
        GlobalState.bar.calendarPanel.open = !GlobalState.bar.calendarPanel.open;
        GlobalState.bar.calendarPanel.screen = section.screen;
      }
    }

    VSeparator {
      Layout.rightMargin: Style.sizes.spacingLarge
    }
  }
}
