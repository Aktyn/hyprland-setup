import QtQuick
import QtQuick.Layouts

import "../../services"
import "../../common"
import "./common"

RowLayout {
  spacing: Style.sizes.spacingMedium

  property alias color: clockText.color

  MaterialSymbol {
    visible: GlobalState.bar.calendarPanel.timer.running
    text: "hourglass"
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
