pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../services"
import "."

Singleton {
  id: root
  property bool ready: false

  property alias bar: configJsonAdapter.bar
  property alias wallpaper: configJsonAdapter.wallpaper
  property alias notifications: configJsonAdapter.notifications
  property alias apps: configJsonAdapter.apps

  FileView {
    path: Consts.path.configFile
    watchChanges: true

    onFileChanged: {
      reload();
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
        property int panelSlideDuration: 350 //ms
      }

      property JsonObject wallpaper: JsonObject {
        property string path: ""

        onPathChanged: {
          if (this.path && Colors.ready && this.path !== Style.wallpaper) {
            ScriptRunner.generateMaterialYouColors(this.path);
          }
        }
      }

      property JsonObject notifications: JsonObject {
        property int defaultTimeout: 8000
      }

      property JsonObject apps: JsonObject {
        property string bluetooth: "blueman-manager"
      }
    }
  }
}
