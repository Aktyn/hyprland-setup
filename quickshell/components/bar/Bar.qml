import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

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

        Component.onCompleted: {
          if (this.WlrLayershell && GlobalState.transparencyEnabled) {
            this.WlrLayershell.namespace = "quickshell:panel";
          }
        }

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
            visible: !GlobalState.transparencyEnabled
            anchors.fill: barBackground
            offset.y: 0
            blur: Style.rounding.hyprland + HyprlandInfo.general.gapsOut[0]
            spread: 0
            color: Colors.transparentize(Style.colors.shadow, Config.bar.shadowOpacity)
          }

          // Background
          Rectangle {
            id: barContainerBackground
            visible: !GlobalState.transparencyEnabled
            anchors.fill: barLayout
            color: "black"
          }

          Rectangle {
            id: barBackground
            anchors.fill: parent
            color: GlobalState.backgroundColor

            topLeftRadius: Style.rounding.hyprland
            topRightRadius: Style.rounding.hyprland
          }

          Rectangle {
            id: contentRoot
            anchors.fill: parent
            color: "transparent"

            RowLayout {
              id: row
              anchors.fill: parent
              spacing: 0

              BarLeft {
                id: leftSection
                implicitWidth: Math.max(0, (contentRoot.width - middleSection.implicitWidth) / 2 - row.spacing)
              }

              BarMiddle {
                id: middleSection
                screen: barPanel.screen
              }

              BarRight {
                implicitWidth: leftSection.implicitWidth
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
            color: GlobalState.backgroundColor
          }

          ReversedRoundedCorner {
            anchors {
              top: parent.top
              right: parent.right
            }

            corner: ReversedRoundedCorner.CornerEnum.TopRight
            color: GlobalState.backgroundColor
          }
        }

        // ------------------------ Dynamic panels ------------------------

        // Left sidebar
        LazyLoader {
          active: true

          BarAdjacentPanel {
            id: leftSidebarContainer

            side: BarAdjacentPanel.Side.Left

            property bool hasFullScreen: !!Hyprland.monitorFor(this.screen).activeWorkspace?.toplevels.values.some(top => top.wayland?.fullscreen)
            adhesive: !hasFullScreen && !GlobalState.transparencyEnabled
            detached: hasFullScreen || GlobalState.transparencyEnabled

            screen: GlobalState.leftSidebar.screen
            show: GlobalState.leftSidebar.open

            closeOnBackgroundClick: GlobalState.leftSidebar.open
            onBackgroundClick: function () {
              GlobalState.leftSidebar.open = false;
            }

            Component.onCompleted: {
              GlobalState.leftSidebar.requestFocus = leftSidebarContainer.onRequestFocus;
            }

            sourceComponent: LeftSidebar {
              Layout.minimumWidth: 384
            }
          }
        }

        //Right sidebar
        LazyLoader {
          active: true

          BarAdjacentPanel {
            id: rightSidebarContainer

            side: BarAdjacentPanel.Side.Right
            adhesive: !GlobalState.transparencyEnabled

            screen: GlobalState.rightSidebar.screen
            show: GlobalState.rightSidebar.open

            closeOnBackgroundClick: GlobalState.rightSidebar.open
            onBackgroundClick: function () {
              GlobalState.rightSidebar.open = false;
            }

            Component.onCompleted: {
              GlobalState.rightSidebar.requestFocus = rightSidebarContainer.onRequestFocus;
            }

            sourceComponent: RightSidebar {
              width: 384
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

            sourceComponent: CalendarPanel {}
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

            sourceComponent: NotesPanel {}
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

            sourceComponent: MediaControls {}
          }
        }
      }
    }
  }
}
