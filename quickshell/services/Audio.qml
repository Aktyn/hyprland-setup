pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
  id: root

  property bool ready: Pipewire.defaultAudioSink?.ready ?? false
  property PwNode sink: Pipewire.defaultAudioSink
  property PwNode source: Pipewire.defaultAudioSource

  signal sinkProtectionTriggered(string reason)

  PwObjectTracker {
    objects: [root.sink, root.source]
  }

  Connections {
    property bool lastReady: false
    property real lastVolume: 0

    // Protection against sudden volume changes
    target: root.sink?.audio ?? null
    onTargetChanged: {
      // Reset protection state when the default sink (or its audio interface) changes
      lastReady = false;
      lastVolume = 0;
    }

    function onVolumeChanged() {
      if (!lastReady) {
        lastVolume = root.sink.audio.volume;
        lastReady = true;
        return;
      }
      const newVolume = root.sink.audio.volume;
      const maxAllowedIncrease = 1; //Config.options.audio.protection.maxAllowedIncrease / 100;
      const maxAllowed = 1; //Config.options.audio.protection.maxAllowed / 100;

      if (newVolume - lastVolume > maxAllowedIncrease) {
        root.sink.audio.volume = lastVolume;
        root.sinkProtectionTriggered("Illegal increment");
      } else if (newVolume > maxAllowed) {
        root.sinkProtectionTriggered("Exceeded max allowed");
        root.sink.audio.volume = Math.min(lastVolume, maxAllowed);
      }
      if (root.sink.ready && (isNaN(root.sink.audio.volume) || root.sink.audio.volume === undefined || root.sink.audio.volume === null)) {
        root.sink.audio.volume = 0;
      }
      lastVolume = root.sink.audio.volume;
    }
  }
}
