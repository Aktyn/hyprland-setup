import QtQuick

import qs.common

TextInput {
  renderType: Text.NativeRendering

  color: Style.colors.colorOnBackground
  selectedTextColor: Style.colors.colorOnSecondaryContainer
  selectionColor: Style.colors.secondaryContainer

  font {
    family: Style.font.family.main ?? "sans-serif"
    pixelSize: Style.font.pixelSize.small
    hintingPreference: Font.PreferFullHinting
  }
}
