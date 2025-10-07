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

    onActiveChanged: {
      console.log("active", this.active);
    }

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

  // Loader {
  //   id: mediaControlsLoader
  //   active: GlobalState.bar.mediaControls.open
  //   onActiveChanged: {
  //     if (!mediaControlsLoader.active && Mpris.players.values.filter(player => isRealPlayer(player)).length === 0) {
  //       GlobalState.bar.mediaControls.open = false;
  //     }
  //   }

  //   sourceComponent: PanelWindow {
  //     id: mediaControlsRoot
  //     visible: true

  //     exclusiveZone: 0
  //     implicitWidth: ((mediaControlsRoot.screen.width / 2) // Middle of screen
  //       - (osdWidth / 2)                 // Dodge OSD
  //       - (widgetWidth / 2)              // Account for widget width
  //     ) * 2
  //     implicitHeight: playerColumnLayout.implicitHeight
  //     color: "transparent"
  //     WlrLayershell.namespace: "quickshell:mediaControls"

  //     anchors {
  //       top: true //!Config.options.bar.bottom
  //       // bottom: Config.options.bar.bottom
  //       left: true
  //     }

  //     // Close when clicking outside the player area
  //     MouseArea {
  //       id: outsideCloser
  //       anchors.fill: parent
  //       hoverEnabled: false
  //       onPressed: function (mouse) {
  //         var p = playerColumnLayout.mapFromItem(outsideCloser, mouse.x, mouse.y);
  //         var inside = p.x >= 0 && p.y >= 0 && p.x <= playerColumnLayout.width && p.y <= playerColumnLayout.height;
  //         if (inside)
  //           mouse.accepted = false;
  //       }
  //       onClicked: function (mouse) {
  //         var p = playerColumnLayout.mapFromItem(outsideCloser, mouse.x, mouse.y);
  //         var inside = p.x >= 0 && p.y >= 0 && p.x <= playerColumnLayout.width && p.y <= playerColumnLayout.height;
  //         if (!inside) {
  //           GlobalState.bar.mediaControls.open = false;
  //         }
  //       }
  //     }

  //   }
  // }

}
