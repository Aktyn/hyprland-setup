pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects

import "../../../common"
import "../../widgets/common"

ColumnLayout {
  id: root

  spacing: Style.sizes.spacingLarge

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

  LabeledHSeparator {
    Layout.alignment: Qt.AlignHCenter

    text: "HDR options"
    color: Style.colors.outline
  }

  GridLayout {
    columns: 2
    columnSpacing: Style.sizes.spacingExtraLarge
    rowSpacing: Style.sizes.spacingMedium
    Layout.alignment: Qt.AlignHCenter

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
  }

  LabeledHSeparator {
    Layout.alignment: Qt.AlignHCenter

    text: Config.wallpaper.path ? "Current wallpaper" : "No wallpaper selected"
    color: Style.colors.outline
  }

  ColumnLayout {
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter

    //TODO: horizontally scrollable strip of recent wallpapers surronding currently selected one; goin left/right will change wallpaper to it
    Rectangle {
      id: wallpaperThumbnailContainer
      visible: !!Config.wallpaper.path

      readonly property int borderWidth: 2
      readonly property int maximumHeight: 256

      Layout.alignment: Qt.AlignHCenter
      Layout.preferredHeight: wallpaperThumbnail.height + borderWidth*2
      Layout.preferredWidth: wallpaperThumbnail.width + borderWidth*2

      color: "transparent"
      border.width: borderWidth
      border.color: colorQuantizer?.colors[0] ?? Style.colors.outlineVariant
      radius: Style.rounding.normal

      ColorQuantizer {
        id: colorQuantizer
        source: Qt.resolvedUrl(Config.wallpaper.path)
        depth: 0
        rescaleSize: 64 // Rescale to 64x64 for faster processing
      }

      Image {
        id: wallpaperThumbnail

        anchors.centerIn: parent

        source: Config.wallpaper.path
        cache: true
        asynchronous: true
        mipmap: true
        fillMode: Image.PreserveAspectFit

        sourceSize {
          height: wallpaperThumbnailContainer.maximumHeight
        }


        layer.enabled: true
        layer.effect: OpacityMask {
          maskSource: Rectangle {
            width: wallpaperThumbnail.width
            height: wallpaperThumbnail.height
            radius: wallpaperThumbnailContainer.radius - wallpaperThumbnailContainer.borderWidth
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
