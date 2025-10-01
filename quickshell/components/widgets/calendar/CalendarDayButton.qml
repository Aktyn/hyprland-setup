import QtQuick
import QtQuick.Layouts

import qs.common
import "../common"

StyledButton {
  id: button
  property string day
  property int isToday
  property bool bold

  Layout.fillWidth: false
  Layout.fillHeight: false
  implicitWidth: 38
  implicitHeight: 38

  toggled: (isToday === 1)
  buttonRadius: Style.rounding.small

  contentItem: StyledText {
    anchors.fill: parent
    text: button.day
    horizontalAlignment: Text.AlignHCenter
    font.weight: button.bold ? Font.DemiBold : Font.Normal
    color: (button.isToday === 1) ? Style.colors.primary : (button.isToday == 0) ? Style.colors.colorOnSurface : Style.colors.outlineVariant

    Behavior on color {
      animation: Style.animation.elementMoveFast.colorAnimation.createObject(this)
    }
  }
}
