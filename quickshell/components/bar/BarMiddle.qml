import QtQuick
import QtQuick.Layouts
import Quickshell

import "../widgets"
import "../widgets/common"
import qs.common

Item {
  id: section
  required property ShellScreen screen

  height: parent.height
  implicitWidth: middleContent.implicitWidth

  RowLayout {
    id: middleContent
    anchors.centerIn: parent
    spacing: Style.sizes.spacingMedium

    StyledButton {
      id: clockWidgetButton

      Layout.alignment: Qt.AlignVCenter
      implicitWidth: clockWidget.width + Style.sizes.spacingMedium * 2
      implicitHeight: clockWidget.height + Style.sizes.spacingExtraSmall * 2

      toggled: GlobalState.bar.calendarPanel.open

      ClockWidget {
        id: clockWidget
        anchors.centerIn: parent
        Layout.alignment: Qt.AlignHCenter
        color: Style.colors.colorOnSurface
      }

      onPressed: {
        GlobalState.bar.calendarPanel.open = !GlobalState.bar.calendarPanel.open;
        GlobalState.bar.calendarPanel.screen = section.screen;
      }
    }

    LazyLoader {
      active: true

      BarAdjacentPanel {
        id: calendarPanelContainer

        screen: GlobalState.bar.calendarPanel.screen
        show: GlobalState.bar.calendarPanel.open

        onBackgroundClick: function () {
          GlobalState.bar.calendarPanel.open = false;
        }

        Component.onCompleted: {
          GlobalState.bar.calendarPanel.requestFocus = calendarPanelContainer.onRequestFocus;
        }

        CalendarPanel {}
      }
    }
  }
}
