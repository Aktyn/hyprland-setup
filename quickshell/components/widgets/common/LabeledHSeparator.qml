import QtQuick
import QtQuick.Layouts

import "../../../common"
import "."

GridLayout {
  id: root

  property string text
  property alias color: label.color

  columns: 3
  columnSpacing: Style.sizes.spacingLarge

  HSeparator {}

  StyledText {
    id: label
    text: root.text
  }

  HSeparator {}
}
