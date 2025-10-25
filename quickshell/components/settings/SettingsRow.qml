import QtQuick
import QtQuick.Layouts

import "../../common"
import "../widgets/common"

ColumnLayout {
  Layout.fillWidth: true
  spacing: Style.sizes.spacingMedium

  property alias label: label.text
  property alias description: description.text

  ColumnLayout {
    Layout.fillWidth: true

    StyledText {
      id: label
      font.pixelSize: Style.font.pixelSize.large
    }

    StyledText {
      id: description
      Layout.fillWidth: true
      wrapMode: Text.Wrap
      font.pixelSize: Style.font.pixelSize.small
      color: Style.colors.outline
    }
  }
}
