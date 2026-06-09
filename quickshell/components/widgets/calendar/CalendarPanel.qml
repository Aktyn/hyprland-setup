import QtQuick
import QtQuick.Layouts

import "."
import ".."
import "../common"
import "../../../common"

RowLayout {
  id: root

  spacing: Style.sizes.spacingLarge

  CalendarWidget {
    id: calendarWidget
  }

  VSeparator {
    Layout.fillHeight: true
    Layout.maximumHeight: root.implicitHeight * 0.618
  }

  //TODO: StopperWidget

  TimerWidget {
    Layout.minimumWidth: calendarWidget.width
  }
}
