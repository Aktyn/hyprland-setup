pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects

import "../../common"

import "../widgets/common"

ColumnLayout {
  id: root

  spacing: Style.sizes.spacingMedium

  ActionButton {
    Layout.fillWidth: true

    iconName: "data_object"
    content: "Open config file"
    onClicked: {
      Quickshell.execDetached(["xdg-open", Consts.path.configFile]);
      GlobalState.rightSidebar.open = false;
      GlobalState.rightSidebar.requestFocus?.(false);
    }
  }

  ColumnLayout {
    spacing: Style.sizes.spacingSmall
    Layout.fillWidth: true

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
        ScriptRunner.selectWallpaperProcess.running = true;
        GlobalState.rightSidebar.requestFocus?.(false)
        GlobalState.rightSidebar.open = false;
      }
    }
  }
}
