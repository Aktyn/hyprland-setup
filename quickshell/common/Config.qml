pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "../services"
import "."

Singleton {
  id: root
  property bool ready: false

  property alias general: configJsonAdapter.general
  property alias bar: configJsonAdapter.bar
  property alias wallpaper: configJsonAdapter.wallpaper
  property alias notifications: configJsonAdapter.notifications
  property alias apps: configJsonAdapter.apps
  property alias workspaces: configJsonAdapter.workspaces

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

      property JsonObject general: JsonObject {
        property bool hideAuthorLink: false
        property int updatesCheckInterval: 60 * 60 * 1000 // 1 hour
        property real panelsTransparency: 0.5 // causes bar and panels to be semi transparent with blurred background; set to 1 to disable transparency effect; requires shell restart if changed from disabled (== 1) to enabled (< 1)
      }

      property JsonObject bar: JsonObject {
        property list<string> screenList: []
        property int height: 36
        property real shadowOpacity: 0.5
        property real desaturateTrayIcons: 0.5 // 1.0 means fully grayscale
        property int panelSlideDuration: 350 //ms

        property JsonObject quickLauncher: JsonObject {
          property list<string> pinnedApps: []
        }
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

      property JsonObject workspaces: JsonObject {
        property int count: 6
      }
    }
  }
}
