pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

import "../../../common"

Item {
  id: root

  property bool colorize: false
  property color color
  property string source: ""
  property string iconFolder: Qt.resolvedUrl(Quickshell.shellPath("assets/icons"))  // The folder to check first
  width: Style.sizes.iconMedium
  height: root.width

  IconImage {
    id: iconImage
    anchors.fill: parent
    source: {
      if (root.iconFolder) {
        return root.iconFolder + "/" + root.source;
      }
      return Qt.resolvedUrl(root.source);
    }
    implicitSize: root.height
  }

  Loader {
    active: root.colorize
    anchors.fill: iconImage
    sourceComponent: ColorOverlay {
      source: iconImage
      color: root.color
    }
  }
}
