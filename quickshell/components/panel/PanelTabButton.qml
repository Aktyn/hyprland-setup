import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../../common"
import "../widgets/common"

TabButton {
  id: root

  required property string iconName
  padding: 0

  contentItem: ColumnLayout {
    id: tabLayout

    Layout.fillWidth: true

    Rectangle {
      Layout.preferredHeight: Style.sizes.spacingSmall
      color: "transparent"
    }

    RowLayout {
      id: tabLabel

      Layout.alignment: Qt.AlignHCenter
      spacing: 8

      property int verticalSlide: root.checked ? Style.sizes.spacingSmall : 0
      Behavior on verticalSlide {
        animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
      }

      Layout.bottomMargin: verticalSlide
      Layout.topMargin: -verticalSlide

      property string color: root.checked ? Style.colors.primary : Style.colors.colorOnSurfaceVariant
      Behavior on color {
        animation: Style.animation.elementMove.colorAnimation.createObject(this)
      }

      MaterialSymbol {
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        text: root.iconName
        iconSize: Style.font.pixelSize.hugeass
        color: tabLabel.color
      }

      StyledText {
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

        text: root.text

        font.pixelSize: Style.font.pixelSize.large
        font.family: Style.font.family.main
        font.weight: Font.DemiBold
        color: tabLabel.color
      }
    }

    Rectangle {
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredHeight: Style.sizes.spacingSmall
      implicitWidth: root.checked ? tabLayout.width - Style.rounding.hyprland / 2 : 0
      color: root.checked ? Style.colors.primary : "transparent"
      radius: Style.rounding.hyprland

      Behavior on implicitWidth {
        animation: Style.animation.elementMove.numberAnimation.createObject(this)
      }
      Behavior on color {
        animation: Style.animation.elementMove.colorAnimation.createObject(this)
      }
    }
  }

  background: Rectangle {
    implicitHeight: 64
    color: Style.colors.surface
  }
}
