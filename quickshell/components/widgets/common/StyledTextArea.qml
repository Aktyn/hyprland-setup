import QtQuick
import QtQuick.Controls

import "../../../common"

TextArea {
  renderType: Text.NativeRendering
  selectedTextColor: Style.colors.colorOnSecondaryContainer
  selectionColor: Style.colors.secondaryContainer
  placeholderTextColor: Style.colors.outline

  font {
    family: Style.font.family.main
    pixelSize: Style.font.pixelSize.small
    hintingPreference: Font.PreferFullHinting
  }
}
