import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris

import "../../../services"
import "../../../common"

import "../common"

Item {
  id: root
  readonly property MprisPlayer activePlayer: MprisController.activePlayer
  readonly property string cleanedTitle: (Utils.cleanMusicTitle(activePlayer?.trackTitle) || "No media  ") //2 spaces for right padding

  implicitWidth: rowLayout.implicitWidth
  implicitHeight: rowLayout.implicitHeight

  Timer {
    running: root.activePlayer?.playbackState == MprisPlaybackState.Playing
    interval: 1000
    repeat: true
    onTriggered: root.activePlayer.positionChanged()
  }

  RowLayout {
    id: rowLayout

    spacing: Style.sizes.spacingMedium
    anchors.centerIn: parent

    CircularProgress {
      Layout.alignment: Qt.AlignVCenter
      value: root.activePlayer?.position / root.activePlayer?.length
      implicitSize: Style.sizes.iconLarge
      colPrimary: Style.colors.colorOnSecondaryContainer
      enableAnimation: true

      MaterialSymbol {
        anchors.centerIn: parent

        text: root.activePlayer?.isPlaying ? "music_note" : "pause"
        iconSize: Style.font.pixelSize.normal
        color: Style.colors.colorOnSurface
      }
    }

    StyledText {
      Layout.preferredWidth: rowLayout.width - (CircularProgress.size + rowLayout.spacing * 2)
      Layout.alignment: Qt.AlignVCenter
      Layout.maximumWidth: 256
      Layout.maximumHeight: Style.sizes.iconLarge
      maximumLineCount: 1

      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
      wrapMode: Text.NoWrap
      color: Style.colors.colorOnSurfaceVariant
      text: `${root.cleanedTitle}${root.activePlayer?.trackArtist ? ' • ' + root.activePlayer.trackArtist : ''}`
      font.pixelSize: Style.font.pixelSize.smaller
    }
  }
}
