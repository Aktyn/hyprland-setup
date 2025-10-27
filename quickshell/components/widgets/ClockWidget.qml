import QtQuick
import QtQuick.Layouts

import "../../common"
import "../../services"

import "./common"

RowLayout {
  property alias color: clockText.color

  CustomIcon {
    visible: GlobalState.bar.calendarPanel.timer.running

    Layout.preferredHeight: Style.sizes.iconMedium
    Layout.preferredWidth: this.Layout.preferredHeight

    source: "timer-sand"
    colorize: true
    color: Style.colors.primary
  }

  Text {
    id: clockText

    Layout.minimumHeight: Style.sizes.iconLarge

    color: Style.colors.colorOnBackground
    text: Time.time
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }
}
