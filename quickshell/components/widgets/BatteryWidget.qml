import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../common"
import "../../services"
import "../widgets/common"

Button {
  id: root

  visible: Battery.available
  property real percentage: Battery.percentage / 100
  property bool isFull: this.percentage >= 0.995

  implicitWidth: layout.implicitWidth
  implicitHeight: layout.implicitHeight
  background: null

  readonly property list<string> icons: ["battery_android_0", "battery_android_1", "battery_android_2", "battery_android_3", "battery_android_4", "battery_android_5", "battery_android_6"]

  property color colorBase: {
    if (this.isFull) {
      const color = Qt.color(Style.colors.error);
      return Qt.hsla((color.hslHue + 0.4) % 1, color.hslSaturation * 0.5, color.hslLightness, 1);
    }

    if (Battery.isCritical) {
      return Style.colors.error;
    }
    if (Battery.isLow) {
      return Colors.mix(Style.colors.colorOnSecondaryContainer, Style.colors.error, 0.5);
    }

    return Style.colors.colorOnSecondaryContainer;
  }

  RowLayout {
    id: layout

    implicitHeight: Style.sizes.heightLarge
    spacing: 0

    CircularProgress {
      value: root.percentage

      lineWidth: 2
      implicitSize: Style.sizes.heightLarge
      colPrimary: root.colorBase
      enableAnimation: false

      MaterialSymbol {
        anchors.centerIn: parent

        text: root.isFull ? "battery_android_full" : root.icons[Utils.clamp(Math.floor(root.icons.length * root.percentage), 0, root.icons.length)]
        iconSize: Style.font.pixelSize.normal
        color: root.colorBase
      }
    }

    MaterialSymbol {
      visible: Battery.isCharging

      text: "bolt"
      color: root.colorBase
    }
  }

  StyledTooltip {
    content: `Battery: ${Math.round(root.percentage * 100)}%${Battery.isCharging ? " and charging" : ""}`
    side: StyledTooltip.TooltipSide.Left
  }
}
