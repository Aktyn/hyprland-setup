import QtQuick
import QtQuick.Controls

import "../../../common"

/**
 * Material 3 progress bar. See https://m3.material.io/components/progress-indicators/overview
 */
ProgressBar {
  id: root
  property real valueBarWidth: 120
  property real valueBarHeight: 4
  property real valueBarGap: 4
  property color highlightColor: Style.colors.primary
  property color trackColor: Style.colors.secondaryContainer
  property bool sperm: false // If true, the progress bar will have a wavy fill effect
  property bool animateSperm: true
  property real spermAmplitudeMultiplier: sperm ? 0.5 : 0
  property real spermFrequency: 6
  property real spermFps: 60

  Behavior on spermAmplitudeMultiplier {
    animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
  }

  Behavior on value {
    animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
  }

  implicitWidth: root.valueBarWidth
  implicitHeight: root.valueBarHeight

  background: Item {
    anchors.fill: parent
  }

  contentItem: Item {
    anchors.fill: parent

    Canvas {
      id: wavyFill
      anchors {
        left: parent.left
        right: parent.right
        verticalCenter: parent.verticalCenter
      }
      height: parent.height * 6
      onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var progress = root.visualPosition;
        var fillWidth = progress * width;
        var amplitude = parent.height * root.spermAmplitudeMultiplier;
        var frequency = root.spermFrequency;
        var phase = Date.now() / 400.0;
        var centerY = height / 2;

        ctx.strokeStyle = root.highlightColor;
        ctx.lineWidth = parent.height;
        ctx.lineCap = "round";
        ctx.beginPath();
        for (var x = ctx.lineWidth / 2; x <= fillWidth; x += 1) {
          var waveY = centerY + amplitude * Math.sin(frequency * 2 * Math.PI * x / width + phase);
          if (x === 0)
            ctx.moveTo(x, waveY);
          else
            ctx.lineTo(x, waveY);
        }
        ctx.stroke();
      }
      Connections {
        target: root
        function onValueChanged() {
          wavyFill.requestPaint();
        }
        function onHighlightColorChanged() {
          wavyFill.requestPaint();
        }
      }
      Timer {
        interval: 1000 / root.spermFps
        running: root.animateSperm
        repeat: root.sperm
        onTriggered: wavyFill.requestPaint()
      }
    }
    Rectangle {
      anchors.right: parent.right
      width: (1 - root.visualPosition) * parent.width - root.valueBarGap
      height: parent.height
      radius: Style.rounding.full ?? 9999
      color: root.trackColor
    }
    Rectangle {
      anchors.right: parent.right
      width: root.valueBarGap
      height: root.valueBarGap
      radius: Style.rounding.full ?? 9999
      color: root.highlightColor
    }
  }
}
