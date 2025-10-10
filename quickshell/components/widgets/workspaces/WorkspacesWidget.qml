import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Hyprland

import "../../../common"
import "../common"
import "."

Item {
  clip: true

  ScrollView {
    anchors.fill: parent

    ScrollBar.horizontal.policy: ScrollBar.AsNeeded
    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

    ScrollBar.horizontal.interactive: true
    ScrollBar.vertical.interactive: false

    //Has to be here for some reason
    Rectangle {
      anchors.fill: parent
      color: "transparent"
    }

    Component.onCompleted: {
      Hyprland.refreshWorkspaces();
    }

    RowLayout {
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      // anchors.verticalCenter: parent.verticalCenter

      spacing: Style.sizes.spacingMedium

      Text {
        //TODO: different approach - expand currently focused workspace by showing all opened window icons and allow scrolling focus within that workspace
        //TODO: list of pinned apps
        text: "TODO: pinned apps"
        color: Style.colors.outlineVariant
        font.pixelSize: Style.font.pixelSize.smaller
      }

      StyledText {
        Layout.alignment: Qt.AlignVCenter

        font.pixelSize: Style.font.pixelSize.larger
        color: Style.colors.outline
        text: "•"
      }

      MouseArea {
        id: mouseArea

        Layout.fillHeight: true
        Layout.preferredHeight: parent.height
        implicitWidth: itemsLayout.implicitWidth

        propagateComposedEvents: true
        cursorShape: Qt.PointingHandCursor

        onWheel: event => {
          if (stagger.running) {
            return;
          }
          stagger.restart();

          if (event.angleDelta.y > 0) {
            if (Hyprland.focusedWorkspace?.id > 1) {
              Hyprland.dispatch(`workspace m-1`);
            }
          } else if (event.angleDelta.y < 0) {
            if (Hyprland.focusedWorkspace?.id < Config.workspaces.count - 1) {
              Hyprland.dispatch(`workspace m+1`);
            }
          }
        }

        RowLayout {
          id: itemsLayout

          anchors.fill: parent

          spacing: Style.sizes.spacingSmall

          Repeater {
            model: Config.workspaces.count ?? 1

            delegate: WorkspaceItem {
              required property int index
              workspace: Hyprland.workspaces.values.find(workspace => workspace.id === this.index + 1) ?? null
              workspaceIndex: index + 1
            }
          }

          Timer {
            id: stagger
            interval: 200
          }
        }
      }
    }
  }
}
