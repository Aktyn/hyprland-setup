pragma Singleton

import QtQuick
import Quickshell
import Qt.labs.platform

Singleton {
  id: root

  property QtObject path: QtObject {
    property string configFile: StandardPaths.standardLocations(StandardPaths.ConfigLocation)[0] + "/aktyn-quickshell/config.json"
    property string colorsFile: StandardPaths.standardLocations(StandardPaths.CacheLocation)[0] + "/aktyn-quickshell/colors.json"
  }
}
