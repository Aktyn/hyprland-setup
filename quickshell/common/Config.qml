pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "."
import "../services"

Singleton {
  id: root
  property bool ready: false

  readonly property string commitHash: commitFile.text() || null
  property alias general: configJsonAdapter.general
  property alias bar: configJsonAdapter.bar
  property alias wallpaper: configJsonAdapter.wallpaper
  property alias battery: configJsonAdapter.battery
  property alias notifications: configJsonAdapter.notifications
  property alias apps: configJsonAdapter.apps
  property alias workspaces: configJsonAdapter.workspaces

  component GeneralConfigType: JsonObject {
    property bool hideAuthorLink: false
    property int updatesCheckInterval: 60 * 60 * 1000 // 1 hour
    property real panelsTransparency: 0.66 // causes bar and panels to be semi transparent with blurred background; set to 1 to disable transparency effect; requires shell restart if changed from disabled (== 1) to enabled (< 1)
  }

  component QuickLauncherConfigType: JsonObject {
    property list<string> pinnedApps: []
  }

  component BarConfigType: JsonObject {
    property list<string> screenList: []
    property int height: 36
    property real shadowOpacity: 1
    property real desaturateTrayIcons: 0.5 // 1.0 means fully grayscale
    property int panelSlideDuration: 350 //ms

    property QuickLauncherConfigType quickLauncher: QuickLauncherConfigType {}
  }

  component WallpaperConfigType: JsonObject {
    property string path: ""

    onPathChanged: {
      if (this.path && Colors.ready && this.path !== Style.wallpaper) {
        ScriptRunner.generateMaterialYouColors(this.path);
      }
    }
  }

  component BatteryConfigType: JsonObject {
    property int low: 20
    property int critical: 5
    property int suspend: 3
    property bool automaticSuspend: true
  }

  component NotificationsConfigType: JsonObject {
    property int defaultTimeout: 8000
  }

  component AppsConfigType: JsonObject {
    property string bluetooth: "blueman-manager"
  }

  component WorkspacesConfigType: JsonObject {
    property int count: 6
  }

  FileView {
    id: commitFile
    path: Qt.resolvedUrl(Consts.path.config + "/quickshell/aktyn/COMMIT.txt")
  }

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

      property GeneralConfigType general: GeneralConfigType {}
      property BarConfigType bar: BarConfigType {}
      property WallpaperConfigType wallpaper: WallpaperConfigType {}
      property BatteryConfigType battery: BatteryConfigType {}
      property NotificationsConfigType notifications: NotificationsConfigType {}
      property AppsConfigType apps: AppsConfigType {}
      property WorkspacesConfigType workspaces: WorkspacesConfigType {}
    }
  }
}
