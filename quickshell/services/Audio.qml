pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
  id: root

  property bool ready: Pipewire.defaultAudioSink?.ready ?? false
  property PwNode sink: Pipewire.defaultAudioSink
  property PwNode source: Pipewire.defaultAudioSource

  PwObjectTracker {
    objects: [root.sink, root.source]
  }

  function onSinkChange() {
    audioConnections.lastReady = false;
  }

  Connections {
    id: audioConnections

    property bool lastReady: false

    target: root.sink?.audio ?? null

    function onVolumeChanged() {
      if (!lastReady) {
        lastReady = true;
        return;
      }
      const newVolume = root.sink.audio.volume;
      const maxAllowedIncrease = 1;
      const maxAllowed = 1;

      if (root.sink.ready && (isNaN(root.sink.audio.volume) || root.sink.audio.volume === undefined || root.sink.audio.volume === null)) {
        root.sink.audio.volume = 0;
      }
    }
  }
}
