pragma Singleton

import QtQuick
import Quickshell
import Qt.labs.platform

import "."

Singleton {
  component SizesType: QtObject {
    readonly property int playerControlWidth: 418 + Style.sizes.spacingExtraLarge * 2
    readonly property int playerControlHeight: 160 + Style.sizes.spacingExtraLarge * 2
  }
  readonly property SizesType sizes: SizesType {}

  component PathType: QtObject {
    readonly property string config: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0]
    readonly property string cache: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0]

    readonly property string configFile: this.config + "/aktyn-quickshell/config.json"
    readonly property string colorsFile: this.cache + "/aktyn-quickshell/colors.json"
    readonly property string recentAppsFile: this.cache + "/aktyn-quickshell/recent.json"
  }
  readonly property PathType path: PathType {}
}
