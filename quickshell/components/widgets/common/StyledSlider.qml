import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

import "../../../common"
import "."

Slider {
  id: root

  property list<real> stopIndicatorValues: [1]
  enum Configuration {
    XS = 12,
    S = 18,
    M = 30,
    L = 42,
    XL = 72
  }

  property var configuration: StyledSlider.Configuration.S

  property real handleDefaultWidth: 3
  property real handlePressedWidth: 1.5

  property color highlightColor: Style.colors.primary
  property color trackColor: Style.colors.secondaryContainer
  property color handleColor: Style.colors.colorOnSecondaryContainer
  property color dotColor: Style.colors.colorOnSecondaryContainer
  property color dotColorHighlighted: Style.colors.colorOnPrimary
  property real unsharpenRadius: Style.rounding.unsharpen
  property real trackWidth: configuration
  property real trackRadius: trackWidth >= StyledSlider.Configuration.XL ? 21 : trackWidth >= StyledSlider.Configuration.L ? 12 : trackWidth >= StyledSlider.Configuration.M ? 9 : 6
  property real handleHeight: Math.max(33, trackWidth + 9)
  property real handleWidth: root.pressed ? handlePressedWidth : handleDefaultWidth
  property real handleMargins: 4
  onHandleMarginsChanged: {
    console.log("Handle margins changed:", handleMargins);
  }
  property real trackDotSize: 3
  property string tooltipContent: `${Math.round(value * 100)}%`

  leftPadding: handleMargins
  rightPadding: handleMargins
  property real effectiveDraggingWidth: width - leftPadding - rightPadding

  Layout.fillWidth: true
  from: 0
  to: 1

  Behavior on value {
    // This makes the adjusted value (like volume) shift smoothly
    SmoothedAnimation {
      velocity: Style.animation.elementMoveFast.velocity
    }
  }

  Behavior on handleMargins {
    animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
  }

  component TrackDot: Rectangle {
    required property real value
    anchors.verticalCenter: parent.verticalCenter
    x: root.handleMargins + (value * root.effectiveDraggingWidth) - (root.trackDotSize / 2)
    width: root.trackDotSize
    height: root.trackDotSize
    radius: Style.rounding.full
    color: value > root.visualPosition ? root.dotColor : root.dotColorHighlighted

    Behavior on color {
      animation: Style.animation.elementMoveFast.colorAnimation.createObject(this)
    }
  }

  MouseArea {
    anchors.fill: parent
    onPressed: mouse => mouse.accepted = false
    cursorShape: root.pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
  }

  background: Item {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    implicitHeight: root.trackWidth

    // Fill left
    Rectangle {
      anchors {
        verticalCenter: parent.verticalCenter
        left: parent.left
      }
      width: root.handleMargins + (root.visualPosition * root.effectiveDraggingWidth) - (root.handleWidth / 2 + root.handleMargins)
      height: root.trackWidth
      color: root.highlightColor
      topLeftRadius: root.trackRadius
      bottomLeftRadius: root.trackRadius
      topRightRadius: root.unsharpenRadius
      bottomRightRadius: root.unsharpenRadius
    }

    // Fill right
    Rectangle {
      anchors {
        verticalCenter: parent.verticalCenter
        right: parent.right
      }
      width: root.handleMargins + ((1 - root.visualPosition) * root.effectiveDraggingWidth) - (root.handleWidth / 2 + root.handleMargins)
      height: root.trackWidth
      color: root.trackColor
      topRightRadius: root.trackRadius
      bottomRightRadius: root.trackRadius
      topLeftRadius: root.unsharpenRadius
      bottomLeftRadius: root.unsharpenRadius
    }

    // Stop indicators
    Repeater {
      model: root.stopIndicatorValues
      TrackDot {
        required property real modelData
        value: modelData
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  handle: Rectangle {
    id: handle

    implicitWidth: root.handleWidth
    implicitHeight: root.handleHeight
    x: root.handleMargins + (root.visualPosition * root.effectiveDraggingWidth) - (root.handleWidth / 2)
    anchors.verticalCenter: parent.verticalCenter
    radius: Style.rounding.full
    color: root.handleColor

    Behavior on implicitWidth {
      animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    StyledTooltip {
      extraVisibleCondition: root.pressed
      content: root.tooltipContent
    }
  }
}
