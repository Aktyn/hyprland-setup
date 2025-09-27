import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Effects

import "../widgets"
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
      if (list.length > 0) {
        return list;
      }

      return screens;
    }

    delegate: Component {
      PanelWindow {
        required property var modelData

        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: Config.bar.height
        aboveWindows: false //TODO: change to true if some areas can be made to ignore pointer events
        color: "transparent"

        implicitHeight: Config.bar.height + HyprlandInfo.decoration.rounding + HyprlandInfo.general.gapsOut[0]

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
            //TODO: use predefined animation from Style.animations
            NumberAnimation {
              duration: 400
              easing.type: Easing.InOutQuad
            }
          }

          // Background shadow
          RectangularShadow {
            anchors.fill: barBackground
            offset.y: 0
            blur: HyprlandInfo.decoration.rounding + HyprlandInfo.general.gapsOut[0]
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

            topLeftRadius: HyprlandInfo.decoration.rounding
            topRightRadius: HyprlandInfo.decoration.rounding
          }

          Rectangle {
            id: contentRoot
            anchors.fill: parent
            anchors.leftMargin: HyprlandInfo.decoration.rounding
            anchors.rightMargin: HyprlandInfo.decoration.rounding * 3
            color: "transparent"

            Row {
              id: row
              anchors.fill: parent
              spacing: 16

              // Left
              BarSection {
                id: leftRect
                width: Math.max(0, (contentRoot.width - middleRect.implicitWidth) / 2)

                ActiveWindowInfo {}

                Text {
                  text: "LEFT"
                  color: "#fff"
                }
              }

              // Middle
              Item {
                id: middleRect
                height: parent.height

                RowLayout {
                  id: middleContent
                  anchors.centerIn: parent
                  spacing: 8

                  ClockWidget {
                    color: Style.colors.colorOnSurface
                  }
                }

                // let implicitWidth follow content
                implicitWidth: middleContent.implicitWidth + 24
              }

              // Right
              BarSection {
                id: rightRect
                width: leftRect.width

                mirror: true

                Text {
                  text: "RIGHT"
                  color: "#fff"
                }
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
