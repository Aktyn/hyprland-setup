import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

import "../../common"
import "../../services"

Item {
  id: root

  required property DesktopEntry entry
  visible: !!this.entry

  implicitHeight: Style.sizes.iconLarge + 2
  implicitWidth: this.implicitHeight

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: event => {
      if (event.button === Qt.LeftButton) {
        const appId = root.entry.id.toLowerCase();
        for (const workspace of Hyprland.workspaces.values) {
          for (const app of workspace.toplevels.values) {
            if (app.wayland?.appId && app.wayland.appId.toLowerCase() === appId) {
              app.wayland.activate(); //It will automatically change workspace
              return;
            }
          }
        }

        root.entry.execute();
      }

      if (event.button === Qt.RightButton) {
        Config.bar.quickLauncher.pinnedApps = Config.bar.quickLauncher.pinnedApps.filter(app => app.toLowerCase() !== root.entry.id.toLowerCase());
      }
    }

    Rectangle {
      anchors.fill: parent
      anchors.margins: -Style.sizes.spacingExtraSmall
      radius: Style.rounding.verysmall

      color: Colors.transparentize(Style.colors.primaryContainer, mouseArea.containsMouse ? 1 : 0)
      Behavior on color {
        animation: Style.animation.elementMoveFast.colorAnimation.createObject(this)
      }
    }
  }

  IconImage {
    id: image

    implicitSize: parent.height

    asynchronous: true
    smooth: true
    mipmap: true

    source: Quickshell.iconPath(AppSearch.guessIcon(root.entry.icon), "image-missing")
    visible: !!this.source

    opacity: mouseArea.containsMouse ? 1 : 0.3
    Behavior on opacity {
      animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Desaturate {
      id: desaturatedIcon

      anchors.fill: image
      source: image
      desaturation: 0.5
    }
  }
}
