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
  property bool adhesive: false //Used for Left and Right side panels to remove distance between screen edge

  default property alias items: panelContent.children
  required property ShellScreen screen
  property bool show: false

  property int innerPadding: Style.sizes.spacingLarge
  readonly property int cornerSize: Style.rounding.hyprland + HyprlandInfo.general.gapsOut[0]
  readonly property int slideDuration: Config.bar.panelSlideDuration

  property int screenEdgeOffset: this.side !== BarAdjacentPanel.Side.Middle && !this.adhesive ? this.cornerSize : 0

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
    property int cornersCount: root.side === BarAdjacentPanel.Side.Middle || !root.adhesive ? 2 : 1
    implicitWidth: panelContent.width + root.innerPadding * 2 + root.cornerSize * this.cornersCount + 2 // + 2 to accommodate borders
    implicitHeight: panelContent.height + root.innerPadding * 2
    visible: !!root.screen

    screen: root.screen

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: contentWrapper.Layout.topMargin > -panel.implicitHeight + HyprlandInfo.general.gapsOut[0]
    color: "transparent"

    anchors.top: true
    margins.top: Config.bar.height
    margins.left: root.side === BarAdjacentPanel.Side.Left ? root.screenEdgeOffset : 0
    margins.right: root.side === BarAdjacentPanel.Side.Right ? root.screenEdgeOffset : 0
    anchors.left: root.side === BarAdjacentPanel.Side.Left
    anchors.right: root.side === BarAdjacentPanel.Side.Right

    HyprlandFocusGrab {
      id: grab
      windows: [panel]

      onActiveChanged: {
        if (!this.active && root.onBackgroundClick && typeof root.onBackgroundClick === "function") {
          root.onBackgroundClick();
        }
      }
    }

    property var onRequestFocus: function (focus = true) {
      if (grab.active !== focus) {
        grab.active = focus;
      }
    }

    RowLayout {
      id: rowLayout

      anchors.fill: parent
      spacing: 0

      property real cornerScale: root.show ? 1 : 0
      Behavior on cornerScale {
        NumberAnimation {
          duration: root.slideDuration
          easing.type: root.show ? Easing.OutQuad : Easing.InQuad
        }
      }

      // Left corner
      ReversedRoundedCorner {
        visible: !root.adhesive || root.side !== BarAdjacentPanel.Side.Left

        Layout.alignment: Qt.AlignTop

        transform: Scale {
          origin.x: root.cornerSize
          origin.y: 0
          xScale: rowLayout.cornerScale
          yScale: rowLayout.cornerScale
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

        implicitHeight: panel.implicitHeight
        Behavior on implicitHeight {
          animation: Style.animation.elementMove.numberAnimation.createObject(this)
          // animation: SequentialAnimation {
          //   PauseAnimation {
          //     duration: 1000
          //   } // Delay in milliseconds
          //   NumberAnimation {
          //     duration: Style.animation.elementMove.duration
          //     easing.type: Style.animation.elementMove.type
          //   }
          // }
        }

        clip: true

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
              easing.type: Easing.InQuad
            }
          },
          Transition {
            from: "visible"
            to: "hidden"
            NumberAnimation {
              properties: "Layout.topMargin"
              duration: root.slideDuration
              easing.type: Easing.OutQuad
            }
          }
        ]

        Rectangle {
          anchors.fill: parent

          color: Style.colors.surface
          bottomLeftRadius: root.adhesive && root.side === BarAdjacentPanel.Side.Left ? 0 : Style.rounding.hyprland
          bottomRightRadius: root.adhesive && root.side === BarAdjacentPanel.Side.Right ? 0 : Style.rounding.hyprland
        }

        Item {
          anchors.fill: parent
          anchors.margins: root.innerPadding
          clip: true

          ColumnLayout {
            id: panelContent
          }
        }
      }

      // Right corner
      ReversedRoundedCorner {
        visible: !root.adhesive || root.side !== BarAdjacentPanel.Side.Right

        Layout.alignment: Qt.AlignTop

        transform: Scale {
          origin.x: 0
          origin.y: 0
          xScale: rowLayout.cornerScale
          yScale: rowLayout.cornerScale
        }

        implicitSize: root.cornerSize
        corner: ReversedRoundedCorner.CornerEnum.TopLeft
        color: Style.colors.surface
      }
    }
  }
}
