import QtQuick

import "../../../common"

Text {
  renderType: Text.NativeRendering
  verticalAlignment: Text.AlignVCenter
  font {
    hintingPreference: Font.PreferFullHinting
    family: Style.font.family.main ?? "sans-serif"
    pixelSize: Style.font.pixelSize.small ?? 15
  }
  color: Style.colors.colorOnBackground ?? "black"
  linkColor: Style.colors.primary
}
