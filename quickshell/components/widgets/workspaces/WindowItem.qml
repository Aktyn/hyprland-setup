import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell.Hyprland
import Quickshell

import "../../../common"
import "../../../services"

//TODO: right click to pin to quick launcher

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
        console.log("left");
      }
      if (event.button === Qt.RightButton) {
        console.log("right");
      }
      if (event.button === Qt.MiddleButton) {
        console.log("middle");
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

    anchors.fill: parent

    cache: false
    smooth: true

    source: Quickshell.iconPath(AppSearch.guessIcon(root.topLevel.wayland.appId), "image-missing")
    visible: !!this.source

    Desaturate {
      id: desaturatedIcon

      anchors.fill: image
      source: image
      desaturation: root.open && root.topLevel.activated ? 0 : 0.75

      Behavior on desaturation {
        animation: Style.animation.elementMove.numberAnimation.createObject(this)
      }
    }

    // ColorOverlay {
    //   anchors.fill: desaturatedIcon
    //   source: desaturatedIcon
    //   color: Colors.transparentize(Style.colors.surfaceContainer, 0.4)
    // }
  }
}
