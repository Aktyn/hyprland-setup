pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root
  property bool ready: false

  property alias bar: configJsonAdapter.bar
  property alias wallpaper: configJsonAdapter.wallpaper

  FileView {
    path: Consts.path.configFile
    watchChanges: true

    onFileChanged: {
      this.reload();
    }

    onAdapterUpdated: writeAdapter()

    onLoaded: {
      root.ready = true;
    }
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound) {
        writeAdapter();
        reload();
      }
    }

    JsonAdapter {
      id: configJsonAdapter

      property JsonObject bar: JsonObject {
        property list<string> screenList: []
        property int height: 36
        property real shadowOpacity: 0.5
        property real desaturateTrayIcons: 0.5 // 1.0 means fully grayscale
      }

      property JsonObject wallpaper: JsonObject {
        property string path: ""
      }
    }
  }
}
