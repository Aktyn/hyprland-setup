import QtQuick
import Quickshell.Hyprland

import "../../../common"
import "../../../services"

Rectangle {
  id: root

  required property HyprlandWorkspace workspace // Can be null
  required property int workspaceIndex

  property bool isEmpty: true //TODO

  property color base: root.workspace?.active ? Colors.mix(Style.colors.inversePrimary, Style.colors.surfaceContainer, 0.25) : Style.colors.surfaceContainer
  property color baseBackground: mouseArea.containsMouse ? Qt.lighter(base, 2) : base
  property color baseForeground: Qt.lighter(baseBackground, 2)

  Behavior on baseBackground {
    animation: Style.animation.elementMove.colorAnimation.createObject(this)
  }

  color: root.baseBackground
  border {
    width: 1
    color: root.baseForeground
  }
  radius: 3

  implicitHeight: Style.sizes.iconMedium
  implicitWidth: Math.round(this.implicitHeight * 1.618)

  MouseArea {
    id: mouseArea

    visible: true //!root.workspace?.active

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      Hyprland.dispatch(`workspace ${root.workspace?.id ?? root.workspaceIndex}`);
    }
  }

  Text {
    anchors.fill: parent
    visible: root.isEmpty

    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter

    color: root.baseForeground
    font {
      weight: 400
      pixelSize: Style.font.pixelSize.smaller
    }
    text: root.workspaceIndex
  }
}
