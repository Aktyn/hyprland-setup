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

      toggled: GlobalState.bar.mainPanel.open

      RowLayout {
        id: clockWidget
        spacing: Style.sizes.spacingMedium
        anchors.centerIn: parent
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

        MaterialSymbol {
          Layout.alignment: Qt.AlignVCenter

          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter

          text: "menu"
          iconSize: Style.font.pixelSize.huge

          property bool isPanelOpen: GlobalState.bar.mainPanel.open

          color: clockWidgetButton.hovered || isPanelOpen ? Style.colors.primary : Qt.darker(Style.colors.colorOnSurface, 3)
          Behavior on color {
            animation: Style.animation.elementMoveFast.colorAnimation.createObject(this)
          }

          scale: clockWidgetButton.hovered && !isPanelOpen ? 1.25 : 1
          Behavior on scale {
            animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
          }
        }

        ClockWidget {
          Layout.alignment: Qt.AlignVCenter
          // id: clockWidget
          color: Time.time.startsWith("13:37") ? Style.colors.primary : Style.colors.colorOnSurface
        }
      }

      onPressed: {
        GlobalState.bar.mainPanel.open = !GlobalState.bar.mainPanel.open;
        GlobalState.bar.mainPanel.screen = section.screen;
      }
    }

    VSeparator {
      Layout.rightMargin: Style.sizes.spacingLarge
    }
  }
}
