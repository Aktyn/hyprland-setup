pragma ComponentBehavior: Bound

import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

import "../../../common"
import "../../../services"

import "../common"
import "."

Item { // Player instance
  id: playerController

  required property MprisPlayer player
  property var artUrl: player?.trackArtUrl
  //TODO: cleanup this directory on shell startup
  property string artDownloadLocation: Consts.path.cache + "/media"
  property string artFileName: Qt.md5(artUrl) + ".jpg"
  property string artFilePath: artDownloadLocation + "/" + artFileName
  property color artDominantColor: colorQuantizer?.colors[0] ?? Style.colors.primaryContainer
  property color foregroundColor: {
    const col = Qt.color(this.artDominantColor);
    if (col.hslLightness < 0.5) {
      col.hslLightness = Math.max(0.75, Math.min(1, col.hslLightness + 0.45));
    } else {
      col.hslLightness = Math.min(0.25, Math.max(0, col.hslLightness - 0.45));
    }
    return col;
  }

  property bool downloaded: false
  property list<real> visualizerPoints: []
  property real maxVisualizerValue: 1000 // Max value in the data points
  property int visualizerSmoothing: 2 // Number of points to average for smoothing

  function seekToPosition(seconds) {
    if (!playerController.player)
      return;
    var len = playerController.player.length || 0;
    if (len <= 0 || isNaN(seconds))
      return;
    var target = Math.max(0, Math.min(len, seconds));
    try {
      if (playerController.player.setPosition) {
        playerController.player.setPosition(target);
      } else if (playerController.player.seek) {
        var current = playerController.player.position || 0;
        playerController.player.seek(target - current);
      } else {
        // Fallback: try assigning directly if supported
        playerController.player.position = target;
      }
      if (playerController.player.positionChanged)
        playerController.player.positionChanged();
    } catch (e)
    // Silently ignore if backend doesn't support seeking
    {}
  }

  component TrackChangeButton: StyledButton {
    id: trackChangeButton

    implicitWidth: contentItem.implicitWidth
    implicitHeight: contentItem.implicitHeight

    property var iconName
    colBackground: Colors.transparentize(playerController.foregroundColor, 0)
    colBackgroundHover: Colors.transparentize(playerController.foregroundColor, 0.25)
    colRipple: Colors.transparentize(playerController.foregroundColor, 0.5)

    contentItem: MaterialSymbol {
      iconSize: Style.font.pixelSize.huge

      horizontalAlignment: Text.AlignHCenter
      color: playerController.foregroundColor
      text: trackChangeButton.iconName

      Behavior on color {
        animation: Style.animation.elementMoveFast.colorAnimation.createObject(this)
      }
    }
  }

  Timer {
    // Force update for prevision
    running: playerController.player?.playbackState == MprisPlaybackState.Playing
    interval: 1000
    repeat: true
    onTriggered: {
      playerController.player.positionChanged();
    }
  }

  onArtUrlChanged: {
    if (playerController.artUrl.length == 0) {
      playerController.artDominantColor = Style.colors.secondaryContainer;
      return;
    }
    playerController.downloaded = false;
    coverArtDownloader.running = true;
  }

  Process { // Cover art downloader
    id: coverArtDownloader
    property string targetFile: playerController.artUrl
    command: ["bash", "-c", "[ -f " + Utils.trimFileProtocol(playerController.artFilePath) + " ] || curl -sSL '" + targetFile + "' -o '" + Utils.trimFileProtocol(playerController.artFilePath) + "'"]
    onExited: (exitCode, exitStatus) => {
      playerController.downloaded = true;
    }
  }

  ColorQuantizer {
    id: colorQuantizer
    source: playerController.downloaded ? Qt.resolvedUrl(playerController.artFilePath) : ""
    depth: 0 // 2^0 = 1 color
    rescaleSize: 4 // Rescale to 1x1 pixel for faster processing
  }

  property bool backgroundIsDark: artDominantColor.hslLightness < 0.5

  RectangularShadow {
    anchors.fill: background
    radius: background.radius
    spread: 0
    blur: Style.sizes.spacingExtraLarge
    color: playerController.artDominantColor // Style.colors.shadow
    cached: true
  }
  Rectangle { // Background
    id: background
    anchors.fill: parent
    anchors.margins: Style.sizes.spacingLarge
    color: "transparent" // playerController.artDominantColor
    radius: Style.rounding.hyprland

    border.width: 1
    border.color: playerController.artDominantColor

    layer.enabled: true
    layer.effect: OpacityMask {
      maskSource: Rectangle {
        width: background.width
        height: background.height
        radius: background.radius
      }
    }

    Image {
      id: blurredArt
      anchors.fill: parent
      source: playerController.downloaded ? Qt.resolvedUrl(playerController.artFilePath) : ""
      sourceSize.width: background.width
      sourceSize.height: background.height
      fillMode: Image.PreserveAspectCrop
      cache: false
      antialiasing: true
      asynchronous: true

      layer.enabled: true
      layer.effect: MultiEffect {
        source: blurredArt
        saturation: 0.2
        blurEnabled: true
        blurMax: 100
        blur: 1
      }

      Rectangle {
        anchors.fill: parent
        color: Colors.transparentize(playerController.artDominantColor, 0.25)
        radius: Style.rounding.hyprland
      }
    }

    WaveVisualizer {
      id: visualizerCanvas
      anchors.fill: parent
      live: playerController.player?.isPlaying
      points: playerController.visualizerPoints
      maxVisualizerValue: playerController.maxVisualizerValue
      smoothing: playerController.visualizerSmoothing
      color: playerController.foregroundColor
    }

    RowLayout {
      anchors.fill: parent
      anchors.margins: Style.sizes.spacingMedium
      spacing: Style.sizes.spacingMedium

      Rectangle { // Art background
        id: artBackground
        Layout.fillHeight: true
        implicitWidth: height
        radius: Style.rounding.hyprland - Style.sizes.spacingMedium
        color: "transparent"

        layer.enabled: true
        layer.effect: OpacityMask {
          maskSource: Rectangle {
            width: artBackground.width
            height: artBackground.height
            radius: artBackground.radius
          }
        }

        Image { // Art image
          id: mediaArt
          property int size: parent.height
          anchors.fill: parent

          source: playerController.downloaded ? Qt.resolvedUrl(playerController.artFilePath) : ""
          fillMode: Image.PreserveAspectCrop
          cache: false
          antialiasing: true
          asynchronous: true

          width: size
          height: size
          sourceSize.width: size
          sourceSize.height: size
        }
      }

      ColumnLayout {
        // Info & controls
        Layout.fillHeight: true
        spacing: Style.sizes.spacingExtraSmall

        StyledText {
          id: trackTitle
          Layout.fillWidth: true
          font.pixelSize: Style.font.pixelSize.large
          color: playerController.foregroundColor
          elide: Text.ElideRight
          text: Utils.cleanMusicTitle(playerController.player?.trackTitle) || "Untitled"
        }
        StyledText {
          id: trackArtist
          Layout.fillWidth: true
          font.pixelSize: Style.font.pixelSize.smaller
          color: Colors.transparentize(playerController.foregroundColor, 0.75)
          elide: Text.ElideRight
          text: playerController.player?.trackArtist
        }
        Item {
          Layout.fillHeight: true
        }
        Item {
          Layout.fillWidth: true
          implicitHeight: trackTime.implicitHeight + sliderRow.implicitHeight

          StyledText {
            id: trackTime
            anchors.bottom: sliderRow.top
            anchors.bottomMargin: 5
            anchors.left: parent.left
            font.pixelSize: Style.font.pixelSize.small
            color: playerController.foregroundColor
            elide: Text.ElideRight
            text: `${Utils.friendlyTimeForSeconds(playerController.player?.position)} / ${Utils.friendlyTimeForSeconds(playerController.player?.length)}`
          }
          RowLayout {
            id: sliderRow
            anchors {
              bottom: parent.bottom
              left: parent.left
              right: parent.right
            }
            TrackChangeButton {
              visible: playerController.player.canGoPrevious
              iconName: "skip_previous"
              onClicked: playerController.player?.previous()
            }
            Item {
              id: progressBarContainer
              Layout.fillWidth: true
              implicitHeight: progressBar.implicitHeight

              StyledProgressBar {
                id: progressBar
                anchors.fill: parent
                highlightColor: playerController.foregroundColor
                trackColor: playerController.artDominantColor
                value: playerController.player?.position / playerController.player?.length
                sperm: playerController.player?.isPlaying
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                property bool dragging: false
                function updateAt(x) {
                  var w = width || 1;
                  var frac = Math.max(0, Math.min(1, x / w));
                  var len = playerController.player?.length || 0;
                  if (len > 0)
                    playerController.seekToPosition(frac * len);
                }
                onPressed: function (mouse) {
                  dragging = true;
                  updateAt(mouse.x);
                }
                onPositionChanged: function (mouse) {
                  if (dragging)
                    updateAt(mouse.x);
                }
                onReleased: function (mouse) {
                  if (dragging) {
                    updateAt(mouse.x);
                    dragging = false;
                  }
                }
              }
            }
            TrackChangeButton {
              visible: playerController.player.canGoNext
              iconName: "skip_next"
              onClicked: playerController.player?.next()
            }
          }

          StyledButton {
            id: playPauseButton
            anchors.right: parent.right
            anchors.bottom: sliderRow.top
            anchors.bottomMargin: 5
            property real size: 44
            implicitWidth: size
            implicitHeight: size
            onClicked: playerController.player.togglePlaying()

            buttonRadius: playerController.player?.isPlaying ? Style.rounding.normal : size / 2
            borderWidth: 1
            borderColor: playerController.foregroundColor
            colBackground: Colors.transparentize(playerController.foregroundColor, 0.25)
            colBackgroundHover: Colors.transparentize(playerController.foregroundColor, 0.75)
            colRipple: Colors.transparentize(playerController.foregroundColor, 0.75)

            contentItem: MaterialSymbol {
              iconSize: Style.font.pixelSize.huge

              horizontalAlignment: Text.AlignHCenter
              color: playerController.foregroundColor
              text: playerController.player?.isPlaying ? "pause" : "play_arrow"

              Behavior on color {
                animation: Style.animation.elementMoveFast.colorAnimation.createObject(this)
              }
            }
          }
        }
      }
    }
  }
}
