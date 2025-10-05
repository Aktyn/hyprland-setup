import QtQuick
import QtQuick.Layouts

import "../widgets/common"
import "../../common"

StyledButton {
  id: root

  property string iconName // Required unless contentItem is custom set

  Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
  implicitWidth: Style.sizes.iconLarge + Style.sizes.spacingExtraSmall * 2
  implicitHeight: root.implicitWidth

  buttonRadius: Style.rounding.full

  property alias color: content.color

  contentItem: MaterialSymbol {
    id: content

    anchors.centerIn: parent
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    width: Style.sizes.iconLarge
    height: Style.sizes.iconLarge

    fill: 0
    text: root.iconName
    iconSize: Style.font.pixelSize.large
    color: root.toggled ? Style.colors.primary : Style.colors.colorOnSurface
  }
}
