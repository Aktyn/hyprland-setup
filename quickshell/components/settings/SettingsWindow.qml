import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "../../common"
import "../widgets/common"

FloatingWindow {
  id: root

  title: "Settings"
  screen: GlobalState.rightSidebar.screen
  implicitWidth: 828
  implicitHeight: 512

  color: Style.colors.surface

  onClosed: GlobalState.rightSidebar.settingsWindowOpen = false

  property url appearanceSettings: "pages/AppearanceSettings.qml"
  property url barSettings: "pages/BarSettings.qml"
  property url workspacesSettings: "pages/WorkspacesSettings.qml"
  property url notificationsSettings: "pages/NotificationsSettings.qml"
  property url batterySettings: "pages/BatterySettings.qml"

  Component.onCompleted: {
    if (this.WlrLayershell && GlobalState.transparencyEnabled) {
      this.WlrLayershell.namespace = "quickshell:panel";
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.sizes.spacingLarge

    StyledText {
      text: "Settings"
      font.pixelSize: Style.font.pixelSize.title
      font.family: Style.font.family.title
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true

      spacing: Style.sizes.spacingLarge

      ColumnLayout {
        Layout.fillHeight: true
        Layout.fillWidth: false
        Layout.preferredWidth: 200

        Rectangle {
          Layout.fillHeight: true
          Layout.fillWidth: true
          color: Style.colors.surfaceContainer
          radius: Style.rounding.normal

          ListView {
            id: categoryList

            anchors.fill: parent
            anchors.margins: Style.sizes.spacingMedium
            clip: true

            model: ["Appearance", "Bar", "Workspaces", "Notifications", "Battery"]
            delegate: ItemDelegate {
              width: parent.width

              background: Rectangle {
                color: parent.highlighted ? Style.colors.primaryContainer : "transparent"
                radius: Style.rounding.small
              }

              contentItem: StyledText {
                text: modelData
                font.pixelSize: Style.font.pixelSize.large
                color: parent.highlighted ? Style.colors.colorOnPrimaryContainer : Style.colors.colorOnSurface
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }

              onClicked: {
                categoryList.currentIndex = index;
                settingsLoader.source = settingsByCategory[modelData];
              }
            }
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Style.sizes.spacingLarge

        clip: true

        StyledText {
          id: settingsTitle
          text: categoryList.currentItem.text
          font.pixelSize: Style.font.pixelSize.huge
          font.family: Style.font.family.title
        }

        Flickable {
          id: flickable
          Layout.fillWidth: true
          Layout.fillHeight: true
          contentHeight: settingsLoader.height

          Loader {
            id: settingsLoader
            width: flickable.width
            source: appearanceSettings
          }
        }
      }
    }
  }

  property var settingsByCategory: {
    "Appearance": appearanceSettings,
    "Bar": barSettings,
    "Workspaces": workspacesSettings,
    "Notifications": notificationsSettings,
    "Battery": batterySettings
  }
}
