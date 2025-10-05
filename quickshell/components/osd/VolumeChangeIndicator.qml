pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import "../../common"
import "../../services"
import "../widgets/common"

Scope {
  id: root
  property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

  function triggerOsd() {
    GlobalState.osd.volumeOpen = true;
    osdTimeout.restart();
  }

  Timer {
    id: osdTimeout
    interval: 3000 //TODO: add to Config
    repeat: false
    running: false
    onTriggered: {
      GlobalState.osd.volumeOpen = false;
    }
  }

  Connections {
    // Listen to volume changes
    target: Audio.sink?.audio ?? null
    function onVolumeChanged() {
      if (!Audio.ready)
        return;
      root.triggerOsd();
    }
    function onMutedChanged() {
      if (!Audio.ready)
        return;
      root.triggerOsd();
    }
  }

  Loader {
    active: GlobalState.osd.volumeOpen

    sourceComponent: PanelWindow {
      id: osdRoot

      Connections {
        target: root
        function onFocusedScreenChanged() {
          osdRoot.screen = root.focusedScreen;
        }
      }

      exclusionMode: ExclusionMode.Normal
      WlrLayershell.namespace: "quickshell:onScreenDisplay"
      WlrLayershell.layer: WlrLayer.Overlay
      color: "transparent"

      anchors {
        top: true
      }
      mask: Region {
        item: osdValuesWrapper
      }

      implicitWidth: columnLayout.implicitWidth
      implicitHeight: columnLayout.implicitHeight
      visible: GlobalState.osd.volumeOpen

      ColumnLayout {
        id: columnLayout

        //TODO: enter/exit animations
        Rectangle {
          id: osdValuesWrapper

          Layout.topMargin: Style.sizes.spacingMedium
          implicitHeight: layout.implicitHeight + Style.sizes.spacingMedium * 2
          implicitWidth: layout.implicitWidth + Style.sizes.spacingMedium * 2

          clip: true

          color: Style.colors.surfaceContainer
          border.color: Style.colors.outlineVariant
          radius: Style.rounding.small

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: GlobalState.osd.volumeOpen = false
          }

          RowLayout {
            id: layout
            anchors.centerIn: parent
            spacing: Style.sizes.spacingMedium

            MaterialSymbol {
              color: Style.colors.colorOnSurface
              text: Audio.sink?.audio.muted ? "volume_off" : "volume_up"
              font.pixelSize: Style.font.pixelSize.small
            }

            Text {
              text: {
                let value = Audio.sink?.audio.volume ?? 0;
                if (isNaN(value)) {
                  value = 0;
                }
                const percentage = Math.round(value * 100);
                return `Volume: ${percentage}%`;
              }
              color: Style.colors.colorOnSurface
              font.weight: Font.DemiBold
              font.pixelSize: Style.font.pixelSize.small
            }
          }
        }
      }
    }
  }

  IpcHandler {
    target: "osdVolume"

    function trigger() {
      root.triggerOsd();
    }

    function hide() {
      GlobalState.osd.volumeOpen = false;
    }

    function toggle() {
      GlobalState.osd.volumeOpen = !GlobalState.osd.volumeOpen;
    }
  }
  GlobalShortcut {
    name: "osdVolumeTrigger"
    description: "Triggers volume OSD on press"

    onPressed: {
      root.triggerOsd();
    }
  }
  GlobalShortcut {
    name: "osdVolumeHide"
    description: "Hides volume OSD on press"

    onPressed: {
      GlobalState.osd.volumeOpen = false;
    }
  }
}
