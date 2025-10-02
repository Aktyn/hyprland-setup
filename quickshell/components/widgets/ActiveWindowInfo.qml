import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import "../../common"
import "./common"

Item {
  id: root
  readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
  readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

  property string activeWindowAddress: `0x${activeWindow?.HyprlandToplevel?.address}`
  property bool focusingThisMonitor: HyprlandInfo.activeWorkspace?.monitor === monitor?.name
  property var biggestWindow: HyprlandInfo.biggestWindowForWorkspace(HyprlandInfo.monitors[root.monitor?.id]?.activeWorkspace.id)

  implicitWidth: Math.min(colLayout.implicitWidth, 384)

  Behavior on implicitWidth {
    animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
  }

  ColumnLayout {
    id: colLayout

    width: root.width
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: -4

    StyledText {
      id: activeWindowClass
      Layout.fillWidth: true

      property string content: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ? root.activeWindow?.appId : (root.biggestWindow?.class) ?? "Desktop"

      visible: this.content.length > 0
      font.pixelSize: Style.font.pixelSize.smaller
      color: Style.colors.outline
      elide: Text.ElideRight
      text: this.content
    }

    StyledText {
      id: activeWindowTitle
      Layout.fillWidth: true
      font.pixelSize: Style.font.pixelSize.small
      color: Style.colors.colorOnSurface
      elide: Text.ElideRight
      text: root.focusingThisMonitor && root.activeWindow?.activated && root.biggestWindow ? root.activeWindow?.title : (root.biggestWindow?.title) ?? `Workspace ${monitor?.activeWorkspace?.id ?? 1}`
    }
  }
}
