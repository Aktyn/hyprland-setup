pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell

import qs.common
import "./common"

ColumnLayout {
  id: root
  spacing: Style.sizes.spacingMedium

  property int h: 0
  property int m: 0
  property int s: 10

  property int totalSeconds: 0
  property int remainingSeconds: 0
  // property bool running: false
  property bool paused: false

  readonly property int fontSize: Math.min(48, implicitWidth / 8)

  function formatTime(time) {
    return time < 10 ? "0" + String(time) : String(time);
  }

  Timer {
    id: countdown
    interval: 1000
    repeat: true
    running: GlobalState.bar.calendarPanel.timer.running && !root.paused
    onTriggered: {
      if (root.remainingSeconds > 0) {
        root.remainingSeconds--;
      } else {
        this.running = false;
        GlobalState.bar.calendarPanel.timer.running = false;
        root.paused = false;
        root.remainingSeconds = 0;

        console.info("Timer finished");
        Quickshell.execDetached(["notify-send", "Timer finished!", "--urgency", "CRITICAL", "--transient", "--icon", Quickshell.shellPath("assets/icons/timer-alert.svg")]);
      }
    }
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

          Layout.alignment: Qt.AlignVCenter
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

            // TextMetrics {
            //   id: textMetrics
            //   font: input.font
            //   text: "00"
            // }
            // width: textMetrics.width + 4

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
          StyledText {
            Layout.alignment: Qt.AlignVCenter
            verticalAlignment: Text.AlignVCenter

            text: timerLayout.index < 2 ? "：" : ""
            color: Style.colors.outline
            font.pixelSize: root.fontSize * 0.618
            visible: timerLayout.index < 2
          }
        }
      }
    }

    ActionButton {
      iconName: "play_arrow"
      content: "Start"

      onClicked: {
        root.totalSeconds = root.h * 3600 + root.m * 60 + root.s;
        if (root.totalSeconds > 0) {
          root.remainingSeconds = root.totalSeconds;
          GlobalState.bar.calendarPanel.timer.running = true;
          root.paused = false;
          countdown.running = true;
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

      property int currentH: Math.floor(root.remainingSeconds / 3600)
      property int currentM: Math.floor((root.remainingSeconds % 3600) / 60)
      property int currentS: root.remainingSeconds % 60

      text: root.formatTime(currentH) + ":" + root.formatTime(currentM) + ":" + root.formatTime(currentS)
      color: Style.colors.colorOnSurface
      font.family: Style.font.family.monospace
      font.pixelSize: root.fontSize
    }

    RowLayout {
      Layout.alignment: Qt.AlignHCenter

      ActionButton {
        iconName: root.paused ? "play_arrow" : "pause"
        content: root.paused ? "Resume" : "Pause"

        onClicked: {
          root.paused = !root.paused;
          countdown.running = !root.paused;
        }
      }

      ActionButton {
        iconName: "replay"
        content: "Reset"

        onClicked: {
          GlobalState.bar.calendarPanel.timer.running = false;
          root.paused = false;
          root.remainingSeconds = 0;
          countdown.running = false;
        }
      }
    }
  }
}
