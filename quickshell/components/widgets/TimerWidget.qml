pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell

import "../../common"
import "./common"

ColumnLayout {
  id: root
  spacing: Style.sizes.spacingMedium

  property int h: 0
  property int m: 0
  property int s: 10

  readonly property int fontSize: Math.min(48, implicitWidth / 8)

  function formatTime(time) {
    return time < 10 ? "0" + String(time) : String(time);
  }

  StyledText {
    Layout.alignment: Qt.AlignHCenter

    text: "Timer"
    color: Style.colors.outline
    font.pixelSize: Style.font.pixelSize.larger
  }

  // Configuration View
  ColumnLayout {
    visible: !GlobalState.bar.calendarPanel.timer.running
    spacing: Style.sizes.spacingSmall
    Layout.preferredWidth: parent.width

    RowLayout {
      Layout.alignment: Qt.AlignHCenter

      Repeater {
        model: [
          {
            "prop": "h",
            "max": 99
          },
          {
            "prop": "m",
            "max": 59
          },
          {
            "prop": "s",
            "max": 59
          }
        ]
        delegate: RowLayout {
          id: timerLayout

          required property var modelData
          required property int index

          Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
          spacing: Style.sizes.spacingExtraSmall

          StyledTextInput {
            id: input
            text: root.formatTime(root[timerLayout.modelData.prop])
            color: Style.colors.colorOnSurfaceVariant
            font.family: Style.font.family.monospace
            font.pixelSize: root.fontSize
            horizontalAlignment: Text.AlignHCenter
            validator: IntValidator {
              bottom: 0
              top: timerLayout.modelData.max
            }
            inputMethodHints: Qt.ImhDigitsOnly
            selectByMouse: true
            maximumLength: 2

            MouseArea {
              anchors.fill: parent
              onClicked: {
                GlobalState.bar.calendarPanel.requestFocus();
                parent.forceActiveFocus();
              }
            }

            onEditingFinished: {
              var value = parseInt(text);
              if (isNaN(value))
                value = 0;
              root[timerLayout.modelData.prop] = value;
              text = root.formatTime(value);
            }

            onActiveFocusChanged: {
              if (activeFocus) {
                selectAll();
              }
            }
          }
          // StyledText {
          MaterialSymbol {
            visible: timerLayout.index < 2

            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.maximumWidth: Style.sizes.iconMedium
            clip: true

            text: "go_to_line"
            color: Style.colors.outline
            font.pixelSize: root.fontSize //* 0.618
          }
        }
      }
    }

    ActionButton {
      iconName: "play_arrow"
      content: "Start"

      onClicked: {
        const totalSeconds = root.h * 3600 + root.m * 60 + root.s;
        if (totalSeconds > 0) {
          GlobalState.bar.calendarPanel.timer.remainingSeconds = totalSeconds;
          GlobalState.bar.calendarPanel.timer.running = true;
          GlobalState.bar.calendarPanel.timer.paused = false;
          GlobalState.bar.calendarPanel.timer.countdownTimer.running = true;
        }
      }
    }
  }

  // Countdown View
  ColumnLayout {
    visible: GlobalState.bar.calendarPanel.timer.running
    spacing: Style.sizes.spacingSmall
    Layout.preferredWidth: parent.width

    StyledText {
      Layout.alignment: Qt.AlignHCenter

      property int currentH: Math.floor(GlobalState.bar.calendarPanel.timer.remainingSeconds / 3600)
      property int currentM: Math.floor((GlobalState.bar.calendarPanel.timer.remainingSeconds % 3600) / 60)
      property int currentS: GlobalState.bar.calendarPanel.timer.remainingSeconds % 60

      text: root.formatTime(currentH) + ":" + root.formatTime(currentM) + ":" + root.formatTime(currentS)
      color: Style.colors.colorOnSurface
      font.family: Style.font.family.monospace
      font.pixelSize: root.fontSize
    }

    RowLayout {
      Layout.alignment: Qt.AlignHCenter

      ActionButton {
        iconName: GlobalState.bar.calendarPanel.timer.paused ? "play_arrow" : "pause"
        content: GlobalState.bar.calendarPanel.timer.paused ? "Resume" : "Pause"

        onClicked: {
          GlobalState.bar.calendarPanel.timer.paused = !GlobalState.bar.calendarPanel.timer.paused;
          GlobalState.bar.calendarPanel.timer.countdownTimer.running = !GlobalState.bar.calendarPanel.timer.paused;
        }
      }

      ActionButton {
        iconName: "replay"
        content: "Reset"

        onClicked: {
          GlobalState.bar.calendarPanel.timer.running = false;
          GlobalState.bar.calendarPanel.timer.paused = false;
          GlobalState.bar.calendarPanel.timer.remainingSeconds = 0;
          GlobalState.bar.calendarPanel.timer.countdownTimer.running = false;
        }
      }
    }
  }
}
