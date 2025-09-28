import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../common"
import "../widgets/common"

Scope {
  id: root
  default property alias items: panelContent.children
  required property ShellScreen screen
  readonly property int innerPadding: Style.sizes.spacingLarge
  readonly property int cornerSize: Style.rounding.hyprland + HyprlandInfo.general.gapsOut[0]
  property bool show: false

  PanelWindow {
    id: panel
    implicitWidth: panelContent.width + root.innerPadding * 2 + root.cornerSize * 2
    implicitHeight: panelContent.height + root.innerPadding * 2
    visible: !!root.screen

    screen: root.screen

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    color: "transparent"

    margins.top: Config.bar.height
    anchors.top: true

    Item {
      id: contentWrapper
      anchors.fill: parent

      state: root.show ? "visible" : "hidden"

      states: [
        State {
          name: "hidden"
          PropertyChanges {
            target: contentWrapper
            anchors.topMargin: -(panelContent.height + root.innerPadding * 2)
          }
        },
        State {
          name: "visible"
          PropertyChanges {
            target: contentWrapper
            anchors.topMargin: 0
          }
        }
      ]

      transitions: [
        Transition {
          from: "hidden"
          to: "visible"
          NumberAnimation {
            properties: "anchors.topMargin"
            duration: 300
            easing.type: Easing.OutCubic
          }
        },
        Transition {
          from: "visible"
          to: "hidden"
          NumberAnimation {
            properties: "anchors.topMargin"
            duration: 250
            easing.type: Easing.InCubic
          }
        }
      ]

      RowLayout {
        anchors.fill: parent
        spacing: 0

        ReversedRoundedCorner {
          Layout.alignment: Qt.AlignTop
          implicitSize: root.cornerSize
          corner: ReversedRoundedCorner.CornerEnum.TopRight
          color: Style.colors.surface
        }
        Rectangle {
          Layout.alignment: Qt.AlignTop
          Layout.fillWidth: true
          implicitHeight: panelContent.height + root.innerPadding * 2
          color: Style.colors.surface
          bottomLeftRadius: Style.rounding.hyprland
          bottomRightRadius: Style.rounding.hyprland
        }
        ReversedRoundedCorner {
          Layout.alignment: Qt.AlignTop
          implicitSize: root.cornerSize
          corner: ReversedRoundedCorner.CornerEnum.TopLeft
          color: Style.colors.surface
        }
      }

      Item {
        anchors.fill: parent
        anchors.margins: root.innerPadding

        opacity: root.show ? 1 : 0
        Behavior on opacity {
          animation: Style.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout {
          id: panelContent
          anchors.centerIn: parent
        }
      }
    }
  }
}
