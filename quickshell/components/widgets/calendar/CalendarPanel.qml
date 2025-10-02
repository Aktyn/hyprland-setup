import QtQuick
import QtQuick.Layouts

import "."
import ".."
import "../common"
import "../../../common"

ColumnLayout {
  spacing: Style.sizes.spacingLarge

  CalendarWidget {}

  HSeparator {}

  TimerWidget {
    Layout.preferredWidth: parent.width
  }
}
