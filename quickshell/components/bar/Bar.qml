import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Effects

import "."
import "../widgets"
import "../widgets/common"
import "../../common"
import "../../services"

LazyLoader {
  id: bar
  active: Config.ready

  property string time

  Variants {
    model: {
      const screens = Quickshell.screens;

      const list = screens.filter(screen => Config.bar.screenList.includes(screen.name));
      return list.length > 0 ? list : screens;
    }

    delegate: Component {
      PanelWindow {
        id: barPanel
        required property var modelData

        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: Config.bar.height
        aboveWindows: false
        color: "transparent"

        implicitHeight: Config.bar.height + Style.rounding.hyprland + HyprlandInfo.general.gapsOut[0]

        anchors {
          top: true
          left: true
          right: true
        }

        Item {
          id: barLayout

          anchors {
            top: parent.top
            left: parent.left
            right: parent.right
          }
          implicitHeight: Config.bar.height

          Behavior on implicitHeight {
            animation: Style.animation.elementMove.numberAnimation.createObject(this)
          }

          // Background shadow
          RectangularShadow {
            anchors.fill: barBackground
            offset.y: 0
            blur: Style.rounding.hyprland + HyprlandInfo.general.gapsOut[0]
            spread: 0
            color: Colors.transparentize("#000", Config.bar.shadowOpacity)
          }

          // Background
          Rectangle {
            anchors {
              fill: parent
            }
            color: "#000"
          }
          Rectangle {
            id: barBackground
            anchors {
              fill: parent
            }
            color: Style.colors.surface

            topLeftRadius: Style.rounding.hyprland
            topRightRadius: Style.rounding.hyprland
          }

          Rectangle {
            id: contentRoot
            anchors.fill: parent
            anchors.leftMargin: Style.rounding.hyprland
            anchors.rightMargin: Style.rounding.hyprland
            color: "transparent"

            Row {
              id: row
              anchors.fill: parent
              spacing: Style.sizes.spacingLarge

              BarLeft {
                id: leftSection
                width: Math.max(0, (contentRoot.width - middleSection.implicitWidth) / 2 - row.spacing)
              }

              BarMiddle {
                id: middleSection
                screen: barPanel.screen
              }

              BarRight {
                width: leftSection.width
                screen: barPanel.screen
              }
            }
          }
        }

        // Rounded decorators
        Item {
          anchors {
            left: parent.left
            right: parent.right
            top: barLayout.bottom
          }

          ReversedRoundedCorner {
            anchors {
              top: parent.top
              left: parent.left
            }

            corner: ReversedRoundedCorner.CornerEnum.TopLeft
            color: Style.colors.surface
          }

          ReversedRoundedCorner {
            anchors {
              top: parent.top
              right: parent.right
            }

            corner: ReversedRoundedCorner.CornerEnum.TopRight
            color: Style.colors.surface
          }
        }
      }
    }
  }
}
