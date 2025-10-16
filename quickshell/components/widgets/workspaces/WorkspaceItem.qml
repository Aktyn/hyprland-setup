pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell

import "../../../common"
import "../../../services"

import "."
import "../common"

Rectangle {
  id: root

  required property HyprlandWorkspace workspace // Can be null
  required property int workspaceIndex

  readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)

  property int windowsCount: (this.workspace?.toplevels.values.filter(v => !!v.wayland) ?? []).length
  opacity: !this.windowsCount ? 0.5 : 1
  property bool isOpened: !!workspace?.active && root.monitor === workspace?.monitor && this.windowsCount > 0

  property color baseColor: root.workspace?.urgent ? Colors.mix(Style.colors.errorContainer, Style.colors.surfaceContainerHighest, 0.2) : root.workspace?.active ? Colors.mix(Style.colors.inversePrimary, Style.colors.surfaceContainerHighest, 0.2) : Style.colors.surfaceContainer
  property color baseBackground: this.isOpened ? Colors.transparentize(this.baseColor, 0) : (mouseArea.containsMouse ? Qt.lighter(baseColor, 2) : baseColor)
  property color baseForeground: Qt.lighter(baseBackground, 2)

  Behavior on baseBackground {
    animation: Style.animation.elementMove.colorAnimation.createObject(this)
  }

  color: root.baseBackground
  border {
    width: 1
    color: root.baseForeground // Colors.transparentize(root.baseForeground, 1, true)
  }
  radius: Style.rounding.unsharpenmore

  // property real monitorRatio: root.workspace ? (root.workspace.monitor.width ?? 1.618) / (root.workspace.monitor.height ?? 1) : 1.618

  implicitHeight: this.isOpened ? Math.min(Style.sizes.iconExtraLarge, parent.height) : Style.sizes.iconLarge

  readonly property int minimumWidth: Math.round(Style.sizes.iconLarge * 1.618)
  readonly property int maximumWidth: 256

  property int baseWindowItemSize: this.isOpened ? Style.sizes.iconExtraLarge - 4 : Style.sizes.iconMedium

  implicitWidth: Utils.clamp(this.windowsCount * (this.baseWindowItemSize - Style.sizes.spacingExtraSmall) + Style.sizes.spacingExtraSmall * 2, this.minimumWidth, this.maximumWidth)

  Behavior on implicitWidth {
    animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
  }
  Behavior on implicitHeight {
    animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
  }

  MouseArea {
    id: mouseArea

    visible: !root.workspace?.active

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: {
      Hyprland.dispatch(`workspace ${root.workspace?.id ?? root.workspaceIndex}`);
    }
  }

  StyledText {
    renderType: Text.QtRendering

    anchors.fill: parent
    visible: !root.windowsCount

    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter

    color: root.baseForeground
    font {
      weight: 400
      pixelSize: Style.font.pixelSize.smaller
    }
    text: root.workspaceIndex
  }

  RowLayout {
    visible: !!root.windowsCount

    anchors.fill: parent
    anchors.margins: Style.sizes.spacingExtraSmall
    clip: true

    spacing: Style.sizes.spacingExtraSmall

    Repeater {
      model: root.workspace?.toplevels.values.filter(v => !!v.wayland)

      delegate: WindowItem {
        required property HyprlandToplevel modelData
        topLevel: modelData
        open: root.isOpened

        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        Layout.preferredHeight: (root.isOpened ? Style.sizes.iconExtraLarge - 4 : Style.sizes.iconMedium) - Style.sizes.spacingExtraSmall * 2
        Layout.preferredWidth: Layout.preferredHeight

        Behavior on Layout.preferredHeight {
          animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
        }
      }
    }
  }
}
