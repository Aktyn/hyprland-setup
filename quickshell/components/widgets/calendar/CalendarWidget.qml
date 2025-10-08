import QtQuick
import QtQuick.Layouts
import "./calendar_layout.js" as CalendarLayout

import "../../../common"
import "../common"
import "."

Item {
  id: root

  property int monthShift: 0
  property var viewingDate: CalendarLayout.getDateInXMonthsTime(monthShift)
  property var calendarLayout: CalendarLayout.getCalendarLayout(viewingDate, monthShift === 0)
  width: calendarColumn.width
  implicitHeight: calendarColumn.height

  Keys.onPressed: event => {
    if ((event.key === Qt.Key_PageDown || event.key === Qt.Key_PageUp) && event.modifiers === Qt.NoModifier) {
      if (event.key === Qt.Key_PageDown) {
        root.monthShift++;
      } else if (event.key === Qt.Key_PageUp) {
        root.monthShift--;
      }
      event.accepted = true;
    }
  }
  MouseArea {
    anchors.fill: parent
    onWheel: event => {
      if (event.angleDelta.y > 0) {
        root.monthShift--;
      } else if (event.angleDelta.y < 0) {
        root.monthShift++;
      }
    }
  }

  ColumnLayout {
    id: calendarColumn
    anchors.centerIn: parent
    spacing: 5

    // Calendar header
    RowLayout {
      Layout.fillWidth: true
      spacing: 5
      CalendarHeaderButton {
        // clip: true
        buttonText: `${root.monthShift !== 0 ? "• " : ""}${root.viewingDate.toLocaleDateString(Qt.locale(), "MMMM yyyy")}`
        tooltipText: (root.monthShift === 0) ? "" : "Jump to current month"
        onClicked: {
          root.monthShift = 0;
        }
      }
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: false
      }
      CalendarHeaderButton {
        forceCircle: true
        onClicked: {
          root.monthShift--;
        }
        contentItem: MaterialSymbol {
          text: "chevron_left"
          iconSize: Style.font.pixelSize.larger
          horizontalAlignment: Text.AlignHCenter
          color: Style.colors.colorOnSurfaceVariant
        }
      }
      CalendarHeaderButton {
        forceCircle: true
        onClicked: {
          root.monthShift++;
        }
        contentItem: MaterialSymbol {
          text: "chevron_right"
          iconSize: Style.font.pixelSize.larger
          horizontalAlignment: Text.AlignHCenter
          color: Style.colors.colorOnSurfaceVariant
        }
      }
    }

    // Week days row
    RowLayout {
      id: weekDaysRow
      Layout.alignment: Qt.AlignHCenter
      Layout.fillHeight: false
      spacing: 5
      Repeater {
        model: CalendarLayout.weekDays
        delegate: CalendarDayButton {
          day: modelData.day
          isToday: modelData.today
          bold: true
          enabled: false
        }
      }
    }

    // Real week rows
    Repeater {
      id: calendarRows

      model: 6
      delegate: RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: false
        spacing: 5
        Repeater {
          model: Array(7).fill(modelData)
          delegate: CalendarDayButton {
            day: calendarLayout[modelData][index].day
            isToday: calendarLayout[modelData][index].today
          }
        }
      }
    }
  }
}
