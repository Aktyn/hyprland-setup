import QtQuick
import Quickshell
import Quickshell.Io

import "../common"

LazyLoader {
  id: bar
  active: Config.ready

  property string time

  Variants {
    model: Quickshell.screens

    delegate: Component {

      PanelWindow {
        id: wallpaperPanel

        required property var modelData

        screen: modelData
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: false
        color: Style.colors.background

        property int topMargin: !GlobalState.transparencyEnabled && (Config.bar.screenList.length === 0 || Config.bar.screenList.includes(screen.name)) ? Config.bar.height : 0

        property int wallpaperWidth: modelData.width // Some reasonable init value, to be updated
        property int wallpaperHeight: modelData.height // Some reasonable init value, to be updated

        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }

        margins {
          top: wallpaperPanel.topMargin
        }

        Text {
          visible: Config.wallpaper.path === ""
          anchors.centerIn: parent
          color: Qt.darker(Style.colors.colorOnSurface, 2)
          text: "No wallpaper selected.\nScreen name: " + screen.name
          font.pointSize: 24
          horizontalAlignment: Text.AlignHCenter
        }

        Image {
          id: wallpaperImage
          visible: Config.wallpaper.path !== ""
          asynchronous: true

          sourceSize {
            width: wallpaperPanel.screen.width
            height: wallpaperPanel.screen.height - wallpaperPanel.topMargin
          }

          property real screenAspect: wallpaperPanel.screen.width / wallpaperPanel.screen.height
          property real bgAspect: wallpaperPanel.wallpaperWidth / wallpaperPanel.wallpaperHeight

          x: screenAspect < bgAspect ? -((wallpaperPanel.wallpaperWidth / wallpaperPanel.wallpaperHeight * sourceSize.height) - sourceSize.width) / 2 : 0
          y: screenAspect > bgAspect ? -((wallpaperPanel.wallpaperHeight / wallpaperPanel.wallpaperWidth * sourceSize.width) - sourceSize.height) / 2 : 0

          source: Config.wallpaper.path
          fillMode: Image.PreserveAspectCrop
        }

        Process {
          id: getWallpaperSizeProc
          property string path: Config.wallpaper.path
          command: ["magick", "identify", "-format", "%w %h", path]
          running: Config.wallpaper.path !== ""
          stdout: StdioCollector {
            id: wallpaperSizeOutputCollector
            onStreamFinished: {
              const output = wallpaperSizeOutputCollector.text;
              const [width, height] = output.split(" ").map(Number);
              wallpaperPanel.wallpaperWidth = width;
              wallpaperPanel.wallpaperHeight = height;
            }
          }
        }
      }
    }
  }
}
