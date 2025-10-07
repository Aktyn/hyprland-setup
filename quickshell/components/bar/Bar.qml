import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell

import "../../common"
import "../../services"

import "."
import "../widgets/common"
import "../widgets/calendar"
import "../widgets/notes"
import "../widgets/audio"
import "../sidebar"

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
            color: Colors.transparentize(Style.colors.shadow, Config.bar.shadowOpacity)
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

            RowLayout {
              id: row
              anchors.fill: parent
              spacing: 0

              BarLeft {
                id: leftSection
                Layout.fillHeight: true
                implicitWidth: Math.max(0, (contentRoot.width - middleSection.implicitWidth) / 2 - row.spacing)
              }

              BarMiddle {
                id: middleSection
                screen: barPanel.screen
              }

              BarRight {
                Layout.fillHeight: true
                implicitWidth: leftSection.width
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

        // ------------------------ Dynamic panels ------------------------

        // Left sidebar
        LazyLoader {
          active: true

          BarAdjacentPanel {
            id: leftSidebarContainer

            side: BarAdjacentPanel.Side.Left
            adhesive: true

            screen: GlobalState.leftSidebar.screen
            show: GlobalState.leftSidebar.open

            closeOnBackgroundClick: GlobalState.leftSidebar.open
            onBackgroundClick: function () {
              GlobalState.leftSidebar.open = false;
            }

            Component.onCompleted: {
              GlobalState.leftSidebar.requestFocus = leftSidebarContainer.onRequestFocus;
            }

            LeftSidebar {
              Layout.minimumWidth: 384
            }
          }
        }

        // Calendar panel sheet
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

        // Notes panel sheet
        LazyLoader {
          active: true

          BarAdjacentPanel {
            id: notesPanelContainer

            screen: GlobalState.bar.notesPanel.screen
            show: GlobalState.bar.notesPanel.open

            onBackgroundClick: function () {
              GlobalState.bar.notesPanel.open = false;
            }

            Component.onCompleted: {
              GlobalState.bar.notesPanel.requestFocus = notesPanelContainer.onRequestFocus;
            }

            NotesPanel {}
          }
        }

        // Media controls panel sheet
        LazyLoader {
          active: true

          BarAdjacentPanel {
            id: mediaControlsPanelContainer

            screen: GlobalState.bar.mediaControls.screen
            show: GlobalState.bar.mediaControls.open
            innerPadding: 0

            onBackgroundClick: function () {
              GlobalState.bar.mediaControls.open = false;
            }

            Component.onCompleted: {
              GlobalState.bar.mediaControls.requestFocus = mediaControlsPanelContainer.onRequestFocus;
            }

            MediaControls {}
          }
        }
      }
    }
  }
}
