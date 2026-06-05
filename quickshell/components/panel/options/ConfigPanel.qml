pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects

import "../../../common"
import "../../widgets/common"

ColumnLayout {
  id: root

  spacing: Style.sizes.spacingMedium

  function closeMainPanel() {
    GlobalState.bar.mainPanel.open = false;
    GlobalState.bar.mainPanel.requestFocus?.(false);
  }

  GridLayout {
    Layout.fillWidth: true

    rows: 1
    columns: 2

    uniformCellWidths: true
    uniformCellHeights: true

    ActionButton {
      Layout.fillWidth: true

      iconName: "data_object"
      content: "Open config file"
      onClicked: {
        Quickshell.execDetached(["xdg-open", Consts.path.configFile]);
        root.closeMainPanel();
      }
    }

    ActionButton {
      Layout.fillWidth: true

      iconName: "settings"
      content: "Open settings"
      onClicked: {
        root.closeMainPanel();
        GlobalState.bar.mainPanel.settingsWindowOpen = true;
      }
    }
  }

  ColumnLayout {
    spacing: Style.sizes.spacingSmall
    Layout.fillWidth: true

    LabeledHSeparator {
      Layout.alignment: Qt.AlignHCenter

      text: "HDR options"
      color: Style.colors.outline
    }

    Repeater {
      id: hdrOptions

      model: HyprlandInfo.monitors
      delegate: RowLayout {
        id: hdrOptionRow

        spacing: Style.sizes.spacingMedium
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter

        required property var modelData

        StyledSwitch {
          checked: HyprlandInfo.monitors.find(monitor => monitor.name === hdrOptionRow.modelData.name && monitor.colorManagementPreset === 'hdr') ?? false
          onCheckedChanged: () => {
            const hdrInfo = HyprlandInfo.monitors.map(monitor => ({
                  name: monitor.name,
                  hdrEnabled: monitor.name === hdrOptionRow.modelData.name ? this.checked : monitor.colorManagementPreset === 'hdr'
                }));
            ScriptRunner.toggleHDRSettings(hdrInfo);
          }
        }

        StyledText {
          Layout.alignment: Qt.AlignVCenter
          text: `Screen ${hdrOptionRow.modelData.name} (${hdrOptionRow.modelData.width}x${hdrOptionRow.modelData.height})`
          color: Style.colors.outline
        }
      }
    }

    LabeledHSeparator {
      Layout.alignment: Qt.AlignHCenter

      text: Config.wallpaper.path ? "Current wallpaper" : "No wallpaper selected"
      color: Style.colors.outline
    }

    Rectangle {
      id: wallpaperThumbnailContainer
      visible: !!Config.wallpaper.path

      Layout.fillWidth: true
      Layout.preferredHeight: wallpaperThumbnail.height + 2

      color: "transparent"
      border.width: 1
      border.color: Style.colors.outlineVariant
      radius: Style.rounding.normal

      Image {
        id: wallpaperThumbnail

        anchors.centerIn: parent

        source: Config.wallpaper.path
        cache: true
        asynchronous: true
        mipmap: true
        fillMode: Image.PreserveAspectFit

        sourceSize {
          width: wallpaperThumbnailContainer.width - 2
        }

        layer.enabled: true
        layer.effect: OpacityMask {
          maskSource: Rectangle {
            width: wallpaperThumbnail.width
            height: wallpaperThumbnail.height
            radius: wallpaperThumbnailContainer.radius
          }
        }
      }
    }

    ActionButton {
      Layout.fillWidth: true

      iconName: "image_search"
      content: "Select wallpaper"

      onClicked: {
        root.closeMainPanel();
        ScriptRunner.selectWallpaperProcess.running = true;
      }
    }
  }
}
