import QtQuick
import QtQuick.Controls

import "../../../common"

Switch {
  id: root
  property real scale: 0.6
  implicitHeight: 32 * root.scale
  implicitWidth: 52 * root.scale
  property color activeColor: Style.colors.primary
  property color inactiveColor: Style.colors.surfaceContainerHighest

  MouseArea {
    anchors.fill: parent
    onPressed: mouse => mouse.accepted = false
    cursorShape: Qt.PointingHandCursor
  }

  // Track
  background: Rectangle {
    width: parent.width
    height: parent.height
    radius: Style.rounding.full ?? 9999
    color: root.checked ? root.activeColor : root.inactiveColor
    border.width: 2 * root.scale
    border.color: root.checked ? root.activeColor : Style.colors.outline

    Behavior on color {
      animation: Style.animation.elementMoveFast.colorAnimation.createObject(this)
    }
    Behavior on border.color {
      animation: Style.animation.elementMoveFast.colorAnimation.createObject(this)
    }
  }

  // Thumb
  indicator: Rectangle {
    width: (root.pressed || root.down) ? (28 * root.scale) : root.checked ? (24 * root.scale) : (16 * root.scale)
    height: (root.pressed || root.down) ? (28 * root.scale) : root.checked ? (24 * root.scale) : (16 * root.scale)
    radius: Style.rounding.full
    color: root.checked ? Style.colors.colorOnPrimary : Style.colors.outline
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: root.checked ? ((root.pressed || root.down) ? (22 * root.scale) : 24 * root.scale) : ((root.pressed || root.down) ? (2 * root.scale) : 8 * root.scale)

    Behavior on anchors.leftMargin {
      animation: Style.animation.elementMove.numberAnimation.createObject(this)
    }
    Behavior on width {
      animation: Style.animation.elementMove.numberAnimation.createObject(this)
    }
    Behavior on height {
      animation: Style.animation.elementMove.numberAnimation.createObject(this)
    }
    Behavior on color {
      animation: Style.animation.elementMoveFast.colorAnimation.createObject(this)
    }
  }
}
