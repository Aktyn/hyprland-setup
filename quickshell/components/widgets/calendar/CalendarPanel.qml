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
    Layout.fillWidth: true
  }

  VSeparator {
    Layout.fillHeight: true
    Layout.maximumHeight: root.implicitHeight * 0.618
  }

  ColumnLayout {
    spacing: Style.sizes.spacingLarge
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter

    StopperWidget {
      Layout.minimumWidth: calendarWidget.width
    }

    HSeparator {}

    TimerWidget {
      Layout.minimumWidth: calendarWidget.width
    }
  }
}
