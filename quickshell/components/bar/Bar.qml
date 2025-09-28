import QtQuick
import Quickshell
import QtQuick.Layouts
import QtQuick.Effects

import "."
import ".."
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

              // Left
              BarSection {
                id: leftRect
                width: Math.max(0, (contentRoot.width - middleRect.implicitWidth) / 2 - row.spacing)

                stretch: true

                // Rectangle {
                //   color: "#80ff5555"
                //   anchors.fill: parent
                // }

                StyledButton {
                  Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                  Layout.fillWidth: false
                  Layout.rightMargin: Style.sizes.spacingMedium
                  property real buttonPadding: Style.sizes.spacingExtraSmall
                  implicitWidth: Math.min(64, Config.bar.height - Style.sizes.spacingSmall * 2)
                  implicitHeight: implicitWidth

                  buttonRadius: Style.rounding.full
                  toggled: false

                  //TODO
                  // GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
                  onPressed: {
                    console.log("Left icon button pressed");
                  }

                  CustomIcon {
                    id: distroIcon
                    anchors.centerIn: parent
                    height: parent.height - parent.buttonPadding * 2
                    width: height

                    source: "aktyn-logo"
                    colorize: true
                    color: Style.colors.colorOnSurface
                  }
                }

                ActiveWindowInfo {}

                // Space separator
                Item {
                  Layout.fillWidth: true
                }

                Text {
                  Layout.alignment: Qt.AlignRight
                  text: "LEFT"
                  color: "#fff"
                }
              }

              // Middle
              Item {
                id: middleRect
                height: parent.height
                implicitWidth: middleContent.implicitWidth

                RowLayout {
                  id: middleContent
                  anchors.centerIn: parent
                  spacing: Style.sizes.spacingMedium

                  property bool openPanel: false

                  StyledButton {
                    id: clockWidgetButton

                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: clockWidget.width + Style.sizes.spacingMedium * 2
                    implicitHeight: clockWidget.height + Style.sizes.spacingExtraSmall * 2

                    toggled: middleContent.openPanel

                    ClockWidget {
                      id: clockWidget
                      anchors.centerIn: parent
                      Layout.alignment: Qt.AlignHCenter
                      color: Style.colors.colorOnSurface
                    }

                    onPressed: {
                      middleContent.openPanel = !middleContent.openPanel;
                      calendarAdjacentPanel.screen = barPanel.screen;
                    }
                  }

                  BarAdjacentPanel {
                    id: calendarAdjacentPanel

                    screen: barPanel.screen
                    show: middleContent.openPanel

                    onShowChanged: {
                      console.log("Test: " + this.show + " | " + middleContent.openPanel)
                    }

                    // Component.onCompleted: {
                    // console.log("Calendar panel loaded " + barPanel.screen);
                    // }
                    CalendarPanel {}
                  }
                }
              }

              // Right
              BarSection {
                id: rightRect
                width: leftRect.width

                mirror: true
                stretch: true

                // Rectangle {
                //   color: "#8055ff55"
                //   anchors.fill: parent
                // }

                Text {
                  text: "TODO: settings panel"
                  color: "#fff"
                }

                SysTray {}

                NetworkBandwidth {}

                // Space separator
                Item {
                  Layout.fillWidth: true
                }

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
