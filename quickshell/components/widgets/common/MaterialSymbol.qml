import QtQuick

import "../../../common"

Text {
  id: root
  property int iconSize: Style.font.pixelSize.small
  property real fill: 0
  property real truncatedFill: Math.round(fill * 100) / 100 // Reduce memory consumption spikes from constant font remapping
  renderType: Text.NativeRendering
  font {
    hintingPreference: Font.PreferFullHinting
    family: Style.font.family.iconMaterial ?? "Material Symbols Rounded"
    pixelSize: root.iconSize
    weight: Font.Normal + (Font.DemiBold - Font.Normal) * fill
    variableAxes: {
      "FILL": truncatedFill,
      // "wght": font.weight,
      // "GRAD": 0,
      "opsz": iconSize
    }
  }
  verticalAlignment: Text.AlignVCenter
  color: Style.colors.colorOnBackground

  // Behavior on fill {
  //     NumberAnimation {
  //         duration: Appearance?.animation.elementMoveFast.duration ?? 200
  //         easing.type: Appearance?.animation.elementMoveFast.type ?? Easing.BezierSpline
  //         easing.bezierCurve: Appearance?.animation.elementMoveFast.bezierCurve ?? [0.34, 0.80, 0.34, 1.00, 1, 1]
  //     }
  // }
}
