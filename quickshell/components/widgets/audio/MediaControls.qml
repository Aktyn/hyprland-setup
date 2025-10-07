import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

import "../../../services"
import "../../../common"

import "."

Item {
  id: root

  readonly property MprisPlayer activePlayer: MprisController.activePlayer

  property var visualizerPoints: []

  Process {
    id: cavaProc
    running: GlobalState.bar.mediaControls.open
    onRunningChanged: {
      if (!cavaProc.running) {
        root.visualizerPoints = [];
      }
    }
    command: ["cava", "-p", Utils.trimFileProtocol(Qt.resolvedUrl(Quickshell.shellPath("scripts")) + "/cava.txt")]
    stdout: SplitParser {
      onRead: data => {
        // Parse `;`-separated values into the visualizerPoints array
        let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
        root.visualizerPoints = points;
      }
    }
  }

  property bool loaded: GlobalState.bar.mediaControls.open
  onLoadedChanged: {
    if (this.loaded) {
      playerControlsLoader.active = true;
      unloadTimeout.running = false;
    } else {
      unloadTimeout.restart();
    }
  }

  Timer {
    id: unloadTimeout
    interval: Config.bar.panelSlideDuration
    repeat: false
    running: false
    onTriggered: {
      playerControlsLoader.active = false;
    }
  }

  implicitWidth: Consts.sizes.playerControlWidth
  implicitHeight: Consts.sizes.playerControlHeight * MprisController.meaningfulPlayers.length + Style.sizes.spacingMedium * Math.max(0, MprisController.meaningfulPlayers.length - 1)

  Loader {
    id: playerControlsLoader

    sourceComponent: ColumnLayout {
      id: playerColumnLayout

      spacing: Style.sizes.spacingMedium

      Repeater {
        model: MprisController.meaningfulPlayers
        delegate: PlayerControl {
          required property MprisPlayer modelData
          player: modelData
          visualizerPoints: root.visualizerPoints

          Layout.alignment: Qt.AlignHCenter
          implicitWidth: Consts.sizes.playerControlWidth
          implicitHeight: Consts.sizes.playerControlHeight
        }
      }
    }
  }
}
