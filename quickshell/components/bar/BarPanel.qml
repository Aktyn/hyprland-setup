pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

import "../../common"
import "../../services"
import "../widgets/common"

Loader {
  id: root

  active: true
  asynchronous: true //TODO: wait for first show to start loading asynchronously
  anchors.horizontalCenter: parent.horizontalCenter

  // default property alias items: panelContent.children
  property Component content
  required property ShellScreen screen
  property bool hasFullScreen: HyprlandInfo.hasFullScreen(this.screen)
  required property bool show
  property bool loadContent: false

  onShowChanged: {
    if (this.show) {
      this.loadContent = true;
      panelContentDelayedUnload.running = false;
    } else {
      panelContentDelayedUnload.running = true; // Start unload timer
    }
  }

  Timer {
    id: panelContentDelayedUnload
    interval: 30000 //30 seconds
    running: false

    onTriggered: {
      console.log("BarPanel unloaded");
      root.loadContent = false;
    }
  }

  // property int innerPadding: Style.sizes.spacingLarge
  // readonly property int radius: Style.rounding.hyprland + (this.detached && root.side !== BarAdjacentPanel.Side.Middle ? HyprlandInfo.general.gapsOut[0] : 0)
  readonly property int radius: Style.rounding.hyprland
  readonly property int cornerSize: this.radius + HyprlandInfo.general.gapsOut[0]

  // property int screenEdgeOffset: this.side !== BarAdjacentPanel.Side.Middle && !this.adhesive ? HyprlandInfo.general.gapsIn[0] : 0

  property bool closeOnBackgroundClick: true
  property var onClose //Does not actually closes the panel. Must be used as callback in parent

  // property alias onRequestFocus: panel.onRequestFocus

  sourceComponent: Item {
    id: rowLayout

    width: panelContentLoader.implicitWidth
    height: root.show ? panelContentLoader.implicitHeight : 0
    clip: false

    anchors.margins: {
      top: Config.bar.height;
    }
    anchors.top: parent.top
    Behavior on height {
      animation: NumberAnimation {
        duration: 600
        easing.type: root.height < 1 ? Easing.InQuad : Easing.OutQuad
      }
    }

    // Intercept clicks inside panel
    MouseArea {
      anchors.fill: parent
      onClicked: function (mouse) {
        mouse.accepted = true;
      }
    }

    readonly property real cornerScaleThreshold: root.cornerSize * 1.5
    property real cornerScale: this.height > this.cornerScaleThreshold ? 1 : this.height/this.cornerScaleThreshold

    ReversedRoundedCorner {
      visible: root.loadContent // !root.detached && (!root.adhesive || root.side !== BarAdjacentPanel.Side.Right)

      anchors.top: parent.top
      anchors.right: parent.left

      transform: Scale {
        origin.x: root.cornerSize
        origin.y: 0
        xScale: rowLayout.cornerScale
        yScale: rowLayout.cornerScale
      }

      implicitSize: root.cornerSize
      corner: ReversedRoundedCorner.CornerEnum.TopRight
      color: GlobalState.backgroundColor
    }

    ReversedRoundedCorner {
      visible: root.loadContent // !root.detached && (!root.adhesive || root.side !== BarAdjacentPanel.Side.Right)

      anchors.top: parent.top
      anchors.left: parent.right

      transform: Scale {
        origin.x: 0
        origin.y: 0
        xScale: rowLayout.cornerScale
        yScale: rowLayout.cornerScale
      }

      implicitSize: root.cornerSize
      corner: ReversedRoundedCorner.CornerEnum.TopLeft
      color: GlobalState.backgroundColor
    }

    Rectangle {
      id: panelBody

      anchors.fill: parent

      color: GlobalState.backgroundColor
      clip: true
      bottomLeftRadius: root.radius
      bottomRightRadius: root.radius

      Loader {
        id: panelContentLoader

        active: root.loadContent
        asynchronous: true
        sourceComponent: root.content
      }
    }
  }
}
