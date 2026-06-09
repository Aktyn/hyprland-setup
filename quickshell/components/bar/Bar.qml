import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import "."
import "../../common"
import "../../services"
import "../panel"
import "../widgets/audio"
import "../widgets/calendar"
import "../widgets/common"
import "../widgets/notes"

LazyLoader {
  id: bar

  property string time

  active: Config.ready

  Variants {
    model: {
      const screens = Quickshell.screens;
      const list = screens.filter((screen) => {
        return Config.bar.screenList.includes(screen.name);
      });
      return list.length > 0 ? list : screens;
    }

    delegate: Component {
      Item {
        id: delegateItem
        required property var modelData


        PanelWindow {
          id: barPanel

          property bool shouldCoverScreen: GlobalState.bar.mainPanel.open
          onShouldCoverScreenChanged: function() {
            if(!shouldCoverScreen) {
              grab.active = false;
            }
          }

          function closePanels() {
            GlobalState.bar.mainPanel.open = false
          }

          screen: delegateItem.modelData
          exclusionMode: ExclusionMode.Ignore
          exclusiveZone: Config.bar.height
          aboveWindows: true 
          color: "transparent"
          WlrLayershell.namespace: "quickshell:panel"
          WlrLayershell.layer: WlrLayer.Top // layer above standard windows
          Component.onCompleted: {
            this.WlrLayershell.namespace = "quickshell:panel";
            this.WlrLayershell.monitor = screen.monitor
            GlobalState.bar.mainPanel.requestFocus = this.onRequestFocus;
          }

          implicitHeight: screen.height
          mask: Region {
            width: barLayout.width
            height: barPanel.shouldCoverScreen ? barPanel.screen.height : barLayout.height
          }

          anchors {
            top: true
            left: true
            right: true
          }

          MouseArea {
            visible: barPanel.shouldCoverScreen
            anchors.fill: parent
            propagateComposedEvents: true
            onClicked: function(event) {
              barPanel.closePanels();
            }
          }

          HyprlandFocusGrab {
            id: grab
            windows: [barPanel]
          }

          function onRequestFocus(focus = true) {
            if (grab.active !== focus) {
              grab.active = focus;
            }
          }

          Item {
            id: barLayout

            implicitHeight: Config.bar.height

            anchors {
              top: parent.top
              left: parent.left
              right: parent.right
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

            Behavior on implicitHeight {
              animation: Style.animation.elementMove.numberAnimation.createObject(this)
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
              corner: ReversedRoundedCorner.CornerEnum.TopLeft
              color: GlobalState.backgroundColor

              anchors {
                top: parent.top
                left: parent.left
              }
            }

            ReversedRoundedCorner {
              corner: ReversedRoundedCorner.CornerEnum.TopRight
              color: GlobalState.backgroundColor

              anchors {
                top: parent.top
                right: parent.right
              }

            }

          }

          BarPanel {
            id: mainPanelContainer

            screen: GlobalState.bar.mainPanel.screen
            show: GlobalState.bar.mainPanel.open

            closeOnBackgroundClick: true
            onClose: function() {
              GlobalState.bar.mainPanel.open = false;
            }

            content: MainPanel {
              screen: GlobalState.bar.mainPanel.screen
            }
          }

          // Notes panel sheet
          LazyLoader {
            loading: true

            component: BarAdjacentPanel {
              id: notesPanelContainer

              screen: GlobalState.bar.notesPanel.screen
              show: GlobalState.bar.notesPanel.open
              onBackgroundClick: function() {
                GlobalState.bar.notesPanel.open = false;
              }
              Component.onCompleted: {
                GlobalState.bar.notesPanel.requestFocus = notesPanelContainer.onRequestFocus;
              }

              sourceComponent: NotesPanel {
              }
            }
          }

          // Media controls panel sheet
          LazyLoader {
            loading: true

            component: BarAdjacentPanel {
              id: mediaControlsPanelContainer

              screen: GlobalState.bar.mediaControls.screen
              show: GlobalState.bar.mediaControls.open
              innerPadding: 0
              onBackgroundClick: function() {
                GlobalState.bar.mediaControls.open = false;
              }
              Component.onCompleted: {
                GlobalState.bar.mediaControls.requestFocus = mediaControlsPanelContainer.onRequestFocus;
              }

              sourceComponent: MediaControls {}
            }
          }
        }


        PanelWindow {
          id: shadowsPanel

          visible: !GlobalState.transparencyEnabled
          color: "transparent" // Window itself is transparent
          screen: delegateItem.modelData
          aboveWindows: true
          exclusionMode: ExclusionMode.Ignore
          WlrLayershell.namespace: "quickshell:shadow"
          WlrLayershell.layer: WlrLayer.Top

          implicitHeight: screen.height

          anchors {
            top: true
            left: true
            right: true
          }

          mask: Region {
            width: 0
            height: 0
          }
          
          RectangularShadow {
            height: Config.bar.height
            width: parent.width
            anchors.top: parent.top
            offset.y: 0
            blur: Style.rounding.hyprland + HyprlandInfo.general.gapsOut[0]
            color: Colors.transparentize(Style.colors.shadow, Config.bar.shadowOpacity)
          }
          RectangularShadow {
            visible: mainPanelContainer.implicitHeight > 0

            height: mainPanelContainer.implicitHeight
            width: mainPanelContainer.implicitWidth
            anchors.horizontalCenter: parent.horizontalCenter
            offset.y: Config.bar.height
            blur: Style.rounding.hyprland + HyprlandInfo.general.gapsOut[0]
            color: Colors.transparentize(Style.colors.shadow, Config.bar.shadowOpacity)
            radius: Style.rounding.hyprland
          }
        }   
      }
    }
  }
}
