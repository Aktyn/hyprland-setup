import QtQuick
import QtQuick.Layouts

import "../widgets/calendar"
import "../widgets/common"
import "../widgets"
import qs.common

ColumnLayout {
  spacing: Style.sizes.spacingLarge

  CalendarWidget {}

  HSeparator {}

  TimerWidget {
    Layout.preferredWidth: parent.width
  }
}
