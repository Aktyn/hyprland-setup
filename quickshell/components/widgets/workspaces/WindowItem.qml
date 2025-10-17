import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Hyprland
import Quickshell

import "../../../common"
import "../../../services"

Item {
  id: root

  required property HyprlandToplevel topLevel
  required property bool open

  MouseArea {
    id: mouseArea

    visible: root.open

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: event => {
      if (event.button === Qt.LeftButton) {
        if (root.topLevel.wayland) {
          const windowOccupyingScreen = root.topLevel.workspace.toplevels.values.find(topLevel => (topLevel.wayland?.maximized || topLevel.wayland?.fullscreen) && topLevel.address !== root.topLevel.address);

          if (windowOccupyingScreen) {
            root.topLevel.wayland.maximized = !!windowOccupyingScreen.wayland?.maximized;
            root.topLevel.wayland.fullscreen = !!windowOccupyingScreen.wayland?.fullscreen;
          }
        }
      }

      if (event.button === Qt.RightButton) {
        Config.bar.quickLauncher.pinnedApps = [...Config.bar.quickLauncher.pinnedApps.filter(app => app !== root.topLevel.wayland.appId), root.topLevel.wayland.appId];
      }

      if (event.button === Qt.MiddleButton) {
        root.topLevel.wayland?.close();
      }
    }

    Rectangle {
      visible: root.open

      anchors.fill: parent
      anchors.margins: -Style.sizes.spacingExtraSmall
      radius: Style.rounding.verysmall

      color: Colors.transparentize(Style.colors.primaryContainer, mouseArea.containsMouse ? 1 : 0)
      Behavior on color {
        animation: Style.animation.elementMoveFast.colorAnimation.createObject(this)
      }
    }
  }

  Image {
    id: image

    width: parent.height
    height: parent.height

    asynchronous: true
    smooth: true
    mipmap: true
    cache: true

    source: Quickshell.iconPath(AppSearch.guessIcon(root.topLevel.wayland.appId), "image-missing")
    visible: !!this.source

    Desaturate {
      id: desaturatedIcon

      anchors.fill: image
      source: image
      desaturation: root.topLevel.activated ? 0 : 0.75

      Behavior on desaturation {
        animation: Style.animation.elementMove.numberAnimation.createObject(this)
      }
    }
  }
}
