import QtQuick
import QtQuick.Layouts

import "../../../common"
import "../../../services"
import "../common"

RowLayout {
  id: root

  MaterialSymbol {
    text: (Audio.sink && Audio.sink.audio && Audio.sink.audio.muted) ? "volume_off" : "volume_up"
    iconSize: Style.font.pixelSize.normal
    color: Style.colors.colorOnSecondaryContainer
  }

  StyledProgressBar {
    id: volumeProgress

    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: 64
    value: {
      const a = Audio.sink && Audio.sink.audio ? Audio.sink.audio : null;
      const v = a ? a.volume : 0;
      if (v === undefined || v === null || isNaN(v))
        return 0;
      return Math.max(0, Math.min(1, v));
    }
    visible: (Audio.sink && Audio.sink.audio)
  }

  WheelHandler {
    id: volumeWheel
    target: root
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function (event) {
      if (!(Audio.sink && Audio.sink.audio)) {
        return;
      }
      let delta = 0;
      if (event.angleDelta && (event.angleDelta.y !== 0 || event.angleDelta.x !== 0)) {
        delta = Math.abs(event.angleDelta.y) >= Math.abs(event.angleDelta.x) ? event.angleDelta.y : event.angleDelta.x;
      } else if (event.pixelDelta && (event.pixelDelta.y !== 0 || event.pixelDelta.x !== 0)) {
        delta = Math.abs(event.pixelDelta.y) >= Math.abs(event.pixelDelta.x) ? event.pixelDelta.y : event.pixelDelta.x;
      }
      if (event.inverted) {
        delta = -delta;
      }
      if (delta === 0) {
        return;
      }

      let baseStep = 0.01;
      let step = (event.modifiers & Qt.ControlModifier) ? baseStep / 2 : baseStep;
      let change = (delta > 0 ? 1 : -1) * step;
      let current = Audio.sink.audio.volume || 0;
      let v = Math.max(0, Math.min(1, current + change));
      if (change > 0 && Audio.sink.audio.muted) {
        Audio.sink.audio.muted = false;
      }
      Audio.sink.audio.volume = v;
      event.accepted = true;
    }
  }
}
