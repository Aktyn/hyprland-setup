import QtQuick
import QtQuick.Controls

import "../../../common"

TextArea {
  renderType: Text.NativeRendering
  selectedTextColor: Style.colors.colorOnSecondaryContainer
  selectionColor: Style.colors.secondaryContainer
  placeholderTextColor: Style.colors.outline

  font {
    family: Style?.font.family.main ?? "sans-serif"
    pixelSize: Style?.font.pixelSize.small ?? 15
    hintingPreference: Font.PreferFullHinting
  }
}
