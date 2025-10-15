import QtQuick
import QtQuick.Layouts

import "../../common"

import "./common"

StyledButton {
  id: root

  required property string iconName

  readonly property int innerPadding: Style.sizes.spacingMedium
  buttonRadius: Style.rounding.verysmall

  implicitWidth: layout.implicitWidth + this.innerPadding * 2
  implicitHeight: layout.implicitHeight + this.innerPadding * 2

  contentItem: ColumnLayout {
    id: layout
    anchors.fill: parent

    spacing: 0

    MaterialSymbol {
      Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter

      text: root.iconName
      iconSize: Style.sizes.iconExtraLarge

      color: Style.colors.colorOnSurface
    }

    StyledText {
      Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
      Layout.bottomMargin: Style.sizes.spacingSmall

      text: root.buttonText
      color: Style.colors.colorOnSurface
      font.pixelSize: Style.font.pixelSize.large
      font.weight: Font.DemiBold
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
