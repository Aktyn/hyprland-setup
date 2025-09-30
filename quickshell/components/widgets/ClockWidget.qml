import QtQuick
import QtQuick.Layouts

import "../../services"
import "../../common"
import "./common"

RowLayout {
  spacing: Style.sizes.spacingMedium

  property alias color: clockText.color

  CustomIcon {
    visible: GlobalState.bar.calendarPanel.timer.running

    height: Style.sizes.iconMedium
    width: height

    source: "timer-sand"
    colorize: true
    color: Style.colors.primary
  }

  Text {
    id: clockText

    color: Style.colors.colorOnBackground
    text: Time.time
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }
}
