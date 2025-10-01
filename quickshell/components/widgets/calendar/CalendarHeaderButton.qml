import QtQuick

import qs.common
import "../common"

StyledButton {
  id: button
  property string buttonText: ""
  property string tooltipText: ""
  property bool forceCircle: false

  implicitHeight: 30
  implicitWidth: forceCircle ? implicitHeight : (contentItem.implicitWidth + 10 * 2)
  Behavior on implicitWidth {
    SmoothedAnimation {
      velocity: 500
    }
  }

  background.anchors.fill: button
  buttonRadius: Style.rounding.full

  contentItem: StyledText {
    text: button.buttonText
    horizontalAlignment: Text.AlignHCenter
    font.pixelSize: Style.font.pixelSize.larger
    color: Style.colors.colorOnSurfaceVariant
  }

  StyledTooltip {
    content: button.tooltipText
    extraVisibleCondition: button.tooltipText.length > 0
  }
}
