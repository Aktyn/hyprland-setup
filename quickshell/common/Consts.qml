pragma Singleton

import QtQuick
import Quickshell
import Qt.labs.platform

import "."

Singleton {
  readonly property QtObject path: QtObject {
    property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    property string cache: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]

    property string configFile: this.config + "/aktyn-quickshell/config.json"
    property string colorsFile: this.cache + "/aktyn-quickshell/colors.json"
    property string dynamicHyprlandConfig: this.config + "/hypr/dynamic.conf"
    property string recentAppsFile: this.cache + "/aktyn-quickshell/recent.json"
  }

  readonly property QtObject sizes: QtObject {
    property int playerControlWidth: 418 + Style.sizes.spacingExtraLarge * 2
    property int playerControlHeight: 160 + Style.sizes.spacingExtraLarge * 2
  }
}
