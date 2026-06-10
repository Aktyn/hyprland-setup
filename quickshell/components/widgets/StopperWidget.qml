pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window

import "../../common"
import "./common"

ColumnLayout {
  id: root
  spacing: Style.sizes.spacingMedium

  readonly property int fontSize: Math.min(48, implicitWidth / 8)

  function formatTime(time) {
    return time < 10 ? "0" + String(time) : String(time);
  }

  StyledText {
    Layout.alignment: Qt.AlignHCenter

    text: "Stopper"
    color: Style.colors.outline
    font.pixelSize: Style.font.pixelSize.larger
  }

  ColumnLayout {
    spacing: Style.sizes.spacingSmall
    Layout.preferredWidth: parent.width

    StyledText {
      Layout.alignment: Qt.AlignHCenter

      property int currentH: Math.floor(GlobalState.bar.calendarPanel.stopper.elapsedSeconds / 3600)
      property int currentM: Math.floor((GlobalState.bar.calendarPanel.stopper.elapsedSeconds % 3600) / 60)
      property int currentS: GlobalState.bar.calendarPanel.stopper.elapsedSeconds % 60

      text: root.formatTime(currentH) + ":" + root.formatTime(currentM) + ":" + root.formatTime(currentS)
      color: Style.colors.colorOnSurface
      font.family: Style.font.family.monospace
      font.pixelSize: root.fontSize
    }

    RowLayout {
      Layout.alignment: Qt.AlignHCenter

      ActionButton {
        property bool isRunning: GlobalState.bar.calendarPanel.stopper.running && !GlobalState.bar.calendarPanel.stopper.paused

        iconName: isRunning ? "pause" : "play_arrow"
        content: isRunning ? "Pause" : (GlobalState.bar.calendarPanel.stopper.paused ? "Resume" : "Start")

        onClicked: {
          if (!GlobalState.bar.calendarPanel.stopper.running) {
            GlobalState.bar.calendarPanel.stopper.running = true;
            GlobalState.bar.calendarPanel.stopper.paused = false;
          } else {
            GlobalState.bar.calendarPanel.stopper.paused = !GlobalState.bar.calendarPanel.stopper.paused;
          }
        }
      }

      ActionButton {
        iconName: "replay"
        content: "Reset"

        onClicked: {
          GlobalState.bar.calendarPanel.stopper.running = false;
          GlobalState.bar.calendarPanel.stopper.paused = false;
          GlobalState.bar.calendarPanel.stopper.elapsedSeconds = 0;
        }
      }
    }
  }
}
