import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import "../../common"
import "../../services"
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
  property bool detached: GlobalState.transparencyEnabled //Should not be combined with adhesive

  default property alias items: panelContent.children
  property Component sourceComponent
  required property ShellScreen screen
  property bool show: false

  onShowChanged: {
    if (this.show) {
      panelContentLoader.active = true;
      panelContentDelayedUnload.running = false;
    } else {
      panelContentDelayedUnload.running = true;
    }
  }

  Timer {
    id: panelContentDelayedUnload
    interval: root.slideDuration
    running: false

    onTriggered: {
      panelContentLoader.active = false;
    }
  }

  property int innerPadding: Style.sizes.spacingLarge
  readonly property int radius: Style.rounding.hyprland + (this.detached && root.side !== BarAdjacentPanel.Side.Middle ? HyprlandInfo.general.gapsOut[0] : 0)
  readonly property int cornerSize: this.radius + HyprlandInfo.general.gapsOut[0]
  readonly property int slideDuration: Config.bar.panelSlideDuration

  property int screenEdgeOffset: this.side !== BarAdjacentPanel.Side.Middle && !this.adhesive ? HyprlandInfo.general.gapsIn[0] : 0

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
    implicitWidth: panelContent.width + root.innerPadding * 2 - 2 + (root.detached ? 0 : root.cornerSize * this.cornersCount) + 2 // + 2 to accommodate borders
    implicitHeight: panelContent.height + root.innerPadding * 2
    visible: !!root.screen

    screen: root.screen

    Component.onCompleted: {
      if (this.WlrLayershell && GlobalState.transparencyEnabled) {
        this.WlrLayershell.namespace = "quickshell:panel";
      }
    }

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: contentWrapper.Layout.topMargin > -panel.implicitHeight + HyprlandInfo.general.gapsOut[0]
    color: "transparent"

    anchors.top: true
    margins.top: root.detached ? Config.bar.height + HyprlandInfo.general.gapsIn[0] : Config.bar.height
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
        visible: !root.detached && (!root.adhesive || root.side !== BarAdjacentPanel.Side.Left)

        Layout.alignment: Qt.AlignTop

        transform: Scale {
          origin.x: root.cornerSize
          origin.y: 0
          xScale: rowLayout.cornerScale
          yScale: rowLayout.cornerScale
        }

        implicitSize: root.cornerSize
        corner: ReversedRoundedCorner.CornerEnum.TopRight
        color: GlobalState.backgroundColor
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

          color: GlobalState.backgroundColor
          topLeftRadius: root.detached ? (root.adhesive && root.side === BarAdjacentPanel.Side.Left ? 0 : root.radius) : 0
          topRightRadius: root.detached ? (root.adhesive && root.side === BarAdjacentPanel.Side.Right ? 0 : root.radius) : 0
          bottomLeftRadius: root.adhesive && root.side === BarAdjacentPanel.Side.Left ? 0 : root.radius
          bottomRightRadius: root.adhesive && root.side === BarAdjacentPanel.Side.Right ? 0 : root.radius

          Rectangle {
            id: containerBorder
            anchors.fill: parent

            gradient: Gradient {
              id: borderGradient

              orientation: Gradient.Vertical
              property color colorBase: Colors.transparentize(Qt.lighter(Style.colors.surface, 2.5), root.show ? 1 : 0, true)
              Behavior on colorBase {
                animation: Style.animation.elementMove.colorAnimation.createObject(this)
              }

              property list<GradientStop> detachedGradientStops: [
                GradientStop {
                  position: 0
                  color: borderGradient.colorBase
                },
                GradientStop {
                  position: 0.5
                  color: Colors.transparentize(borderGradient.colorBase, 0, true)
                },
                GradientStop {
                  position: 1
                  color: borderGradient.colorBase
                }
              ]
              property list<GradientStop> gradientStops: [
                GradientStop {
                  position: root.cornerSize / containerBorder.height
                  color: Colors.transparentize(borderGradient.colorBase, 0, true)
                },
                GradientStop {
                  position: 1
                  color: borderGradient.colorBase
                }
              ]

              stops: root.detached ? detachedGradientStops : gradientStops
            }
            opacity: 0.15

            bottomLeftRadius: parent.bottomLeftRadius
            bottomRightRadius: parent.bottomRightRadius
            topLeftRadius: parent.topLeftRadius
            topRightRadius: parent.topRightRadius
          }

          Rectangle {
            id: mask
            anchors.fill: parent
            // anchors.margins: -1

            bottomLeftRadius: parent.bottomLeftRadius
            bottomRightRadius: parent.bottomRightRadius
            topLeftRadius: parent.topLeftRadius
            topRightRadius: parent.topRightRadius
            border.width: 1 //root.borderWidth
            color: 'transparent'
            visible: false   // otherwise a thin border might be seen.

          }

          OpacityMask {
            id: opM
            anchors.fill: parent
            anchors.leftMargin: root.adhesive && root.side === BarAdjacentPanel.Side.Left ? -1 : 0
            anchors.rightMargin: root.adhesive && root.side === BarAdjacentPanel.Side.Right ? -1 : 0

            source: containerBorder
            maskSource: mask
          }
        }

        Item {
          anchors.fill: parent
          anchors.margins: root.innerPadding
          clip: true

          ColumnLayout {
            id: panelContent

            Loader {
              id: panelContentLoader

              active: false
              sourceComponent: root.sourceComponent
            }
          }
        }
      }

      // Right corner
      ReversedRoundedCorner {
        visible: !root.detached && (!root.adhesive || root.side !== BarAdjacentPanel.Side.Right)

        Layout.alignment: Qt.AlignTop

        transform: Scale {
          origin.x: 0
          origin.y: 0
          xScale: rowLayout.cornerScale
          yScale: rowLayout.cornerScale
        }

        implicitSize: root.cornerSize
        corner: ReversedRoundedCorner.CornerEnum.TopLeft
        color: GlobalState.backgroundColor
      }
    }
  }
}
