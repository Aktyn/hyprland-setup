import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

import "../../common"
import "../widgets/common"

Scope {
  id: root

  enum Side {
    Middle = 1,
    Left = 3,
    Right = 4
  }
  property int side: BarAdjacentPanel.Side.Middle

  default property alias items: panelContent.children
  required property ShellScreen screen
  property bool show: false

  readonly property int innerPadding: Style.sizes.spacingLarge
  readonly property int cornerSize: Style.rounding.hyprland + HyprlandInfo.general.gapsOut[0]
  readonly property int slideDuration: 300

  property bool closeOnBackgroundClick: true
  property var onBackgroundClick

  property alias onRequestFocus: panel.onRequestFocus

  PanelWindow {
    id: pointerCatcher

    screen: root.screen
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    margins.top: Config.bar.height

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    visible: root.show && root.closeOnBackgroundClick

    color: "transparent"

    MouseArea {
      anchors.fill: parent
      onClicked: {
        if (root.onBackgroundClick && typeof root.onBackgroundClick === "function") {
          root.onBackgroundClick();
        }
      }
    }
  }

  PanelWindow {
    id: panel
    implicitWidth: panelContent.width + root.innerPadding * 2 + root.cornerSize * 2
    implicitHeight: panelContent.height + root.innerPadding * 2
    visible: !!root.screen

    screen: root.screen

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: contentWrapper.Layout.topMargin > -panel.implicitHeight + HyprlandInfo.general.gapsOut[0]
    color: "transparent"

    anchors.top: true
    margins.top: Config.bar.height
    anchors.left: root.side === BarAdjacentPanel.Side.Left
    anchors.right: root.side === BarAdjacentPanel.Side.Right

    HyprlandFocusGrab {
      id: grab
      windows: [panel]
    }

    property var onRequestFocus: function () {
      grab.active = true;
    }

    RowLayout {
      id: rowLayout

      anchors.fill: parent
      spacing: 0

      property int cornersY: root.show ? 0 : -root.cornerSize
      property int cornerSlideDuration: root.slideDuration

      ReversedRoundedCorner {
        Layout.alignment: Qt.AlignTop

        Layout.topMargin: rowLayout.cornersY
        Behavior on Layout.topMargin {
          NumberAnimation {
            duration: rowLayout.cornerSlideDuration
            easing.type: root.show ? Easing.InCubic : Easing.OutCubic
          }
        }

        implicitSize: root.cornerSize
        corner: ReversedRoundedCorner.CornerEnum.TopRight
        color: Style.colors.surface
      }

      Item {
        id: contentWrapper
        Layout.alignment: Qt.AlignTop
        Layout.fillWidth: true
        Layout.topMargin: 0

        state: root.show ? "visible" : "hidden"

        states: [
          State {
            name: "hidden"
            PropertyChanges {
              target: contentWrapper
              Layout.topMargin: -panel.implicitHeight
            }
          },
          State {
            name: "visible"
            PropertyChanges {
              target: contentWrapper
              Layout.topMargin: 0
            }
          }
        ]

        transitions: [
          Transition {
            from: "hidden"
            to: "visible"
            NumberAnimation {
              properties: "Layout.topMargin"
              duration: root.slideDuration
              easing.type: Easing.OutCubic
            }
          },
          Transition {
            from: "visible"
            to: "hidden"
            NumberAnimation {
              properties: "Layout.topMargin"
              duration: root.slideDuration
              easing.type: Easing.InCubic
            }
          }
        ]

        Rectangle {
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          implicitHeight: panel.implicitHeight
          color: Style.colors.surface
          bottomLeftRadius: Style.rounding.hyprland
          bottomRightRadius: Style.rounding.hyprland
        }

        Item {
          anchors.fill: parent
          anchors.margins: root.innerPadding

          ColumnLayout {
            id: panelContent
            opacity: root.show ? 1 : 0
            Behavior on opacity {
              animation: Style.animation.elementMove.numberAnimation.createObject(this)
            }
          }
        }
      }

      ReversedRoundedCorner {
        Layout.alignment: Qt.AlignTop

        Layout.topMargin: rowLayout.cornersY
        Behavior on Layout.topMargin {
          NumberAnimation {
            duration: rowLayout.cornerSlideDuration
            easing.type: root.show ? Easing.InCubic : Easing.OutCubic
          }
        }

        implicitSize: root.cornerSize
        corner: ReversedRoundedCorner.CornerEnum.TopLeft
        color: Style.colors.surface
      }
    }
  }
}
