import QtQuick
import QtQuick.Layouts

import "../../../common"
import "."

StyledButton {
  id: root

  Layout.alignment: Qt.AlignHCenter

  //TODO: allow entire component (check with typeof whether to render as StyledText or provided component)
  property string iconName
  property string content
  property int size: Style.font.pixelSize.normal
  padding: Style.sizes.spacingMedium
  property color color: Style.colors.colorOnSurface

  implicitWidth: layout.implicitWidth + this.padding * 2
  implicitHeight: layout.implicitHeight + this.padding * 2

  RowLayout {
    id: layout

    anchors.centerIn: parent
    spacing: Style.sizes.spacingMedium

    MaterialSymbol {
      visible: !!root.icon
      text: root.iconName
      iconSize: root.size * 1.35
      color: root.color
    }
    StyledText {
      visible: !!root.content
      Layout.alignment: Qt.AlignVCenter

      text: root.content
      color: root.color
      font.pixelSize: root.size
    }
  }
}
