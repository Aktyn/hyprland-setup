import QtQuick

import "../../../common"

Text {
  id: root
  property int iconSize: Style.font.pixelSize.small
  // renderType: Text.NativeRendering
  font {
    hintingPreference: Font.PreferFullHinting
    family: Style.font.family.iconMaterial ?? "Material Symbols Rounded"
    pixelSize: root.iconSize
    weight: Font.Normal
    variableAxes: {
      // "wght": font.weight,
      // "GRAD": 0,
      "opsz": iconSize
    }
  }
  verticalAlignment: Text.AlignVCenter
  horizontalAlignment: Text.AlignHCenter
  color: Style.colors.colorOnBackground
}
