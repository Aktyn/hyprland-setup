import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls

import qs.common
import qs.services

Button {
  id: root

  property bool toggled
  property string buttonText
  property real buttonRadius: Style.rounding.small
  property real buttonRadiusPressed: buttonRadius
  property real buttonEffectiveRadius: root.down ? root.buttonRadiusPressed : root.buttonRadius
  readonly property int rippleDuration: 600
  property bool rippleEnabled: true
  property var downAction // When left clicking (down)
  property var releaseAction // When left clicking (release)
  property var altAction // When right clicking
  property var middleClickAction // When middle clicking

  property color colBackground: Colors.transparentize(Style.colors.colorOnSurfaceVariant, 0)
  property color colBackgroundHover: Colors.transparentize(Style.colors.colorOnSurfaceVariant, 0.25)
  property color colBackgroundToggled: Colors.transparentize(Style.colors.primaryContainer, 0.25)
  property color colBackgroundToggledHover: Colors.transparentize(Style.colors.primaryContainer, 0.75)
  property color colRipple: Style.colors.colorOnSurface
  property color colRippleToggled: Style.colors.colorOnPrimaryContainer
  property color borderColor: root.toggled ? Colors.transparentize(Style.colors.primary, 0.5) : "transparent"

  opacity: root.enabled ? 1 : 0.4
  property color buttonColor: root.enabled ? (root.toggled ? (root.hovered ? colBackgroundToggledHover : colBackgroundToggled) : (root.hovered ? colBackgroundHover : colBackground)) : colBackground
  property color rippleColor: root.toggled ? colRippleToggled : colRipple

  function startRipple(x, y) {
    const stateY = buttonBackground.y;
    rippleAnim.x = x;
    rippleAnim.y = y - stateY;

    const dist = (ox, oy) => ox * ox + oy * oy;
    const stateEndY = stateY + buttonBackground.height;
    rippleAnim.radius = Math.sqrt(Math.max(dist(0, stateY), dist(0, stateEndY), dist(width, stateY), dist(width, stateEndY)));

    rippleFadeAnim.complete();
    rippleAnim.restart();
  }

  component RippleAnim: NumberAnimation {
    duration: rippleDuration
    easing.type: Easing.InQuad
    // easing.type: Style.animation.elementMoveEnter.type
    // easing.bezierCurve: Style.animationCurves.standardDecel
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onPressed: event => {
      if (event.button === Qt.RightButton) {
        if (root.altAction)
          root.altAction();
        return;
      }
      if (event.button === Qt.MiddleButton) {
        if (root.middleClickAction)
          root.middleClickAction();
        return;
      }
      root.down = true;
      if (root.downAction) {
        root.downAction();
      }
      if (!root.rippleEnabled) {
        return;
      }

      const {
        x,
        y
      } = event;
      startRipple(x, y);
    }
    onReleased: event => {
      root.down = false;
      if (event.button !== Qt.LeftButton) {
        return;
      }
      if (root.releaseAction) {
        root.releaseAction();
      }
      root.click(); // Because the MouseArea already consumed the event
      if (!root.rippleEnabled) {
        return;
      }
      rippleFadeAnim.restart();
    }
    onCanceled: event => {
      root.down = false;
      if (!root.rippleEnabled) {
        return;
      }
      rippleFadeAnim.restart();
    }
  }

  RippleAnim {
    id: rippleFadeAnim
    duration: root.rippleDuration * 2
    target: ripple
    property: "opacity"
    to: 0
  }

  SequentialAnimation {
    id: rippleAnim

    property real x
    property real y
    property real radius

    PropertyAction {
      target: ripple
      property: "x"
      value: rippleAnim.x
    }
    PropertyAction {
      target: ripple
      property: "y"
      value: rippleAnim.y
    }
    PropertyAction {
      target: ripple
      property: "opacity"
      value: 1
    }
    ParallelAnimation {
      RippleAnim {
        target: ripple
        properties: "implicitWidth,implicitHeight"
        from: 0
        to: rippleAnim.radius * 2
      }
    }
  }

  background: Rectangle {
    id: buttonBackground
    radius: root.buttonEffectiveRadius
    implicitHeight: 50

    color: root.buttonColor
    border.color: root.borderColor
    border.width: root.toggled ? 1 : 0
    Behavior on color {
      animation: Style.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    layer.enabled: true
    layer.effect: OpacityMask {
      maskSource: Rectangle {
        width: buttonBackground.width
        height: buttonBackground.height
        radius: root.buttonEffectiveRadius
      }
    }

    Item {
      id: ripple
      width: ripple.implicitWidth
      height: ripple.implicitHeight
      opacity: 0
      visible: width > 0 && height > 0

      property real implicitWidth: 0
      property real implicitHeight: 0

      Behavior on opacity {
        animation: Style.animation.elementMoveFast.colorAnimation.createObject(this)
      }

      RadialGradient {
        anchors.fill: parent
        gradient: Gradient {
          GradientStop {
            position: 0.0
            color: root.rippleColor
          }
          GradientStop {
            position: 0.3
            color: root.rippleColor
          }
          GradientStop {
            position: 0.5
            color: Qt.rgba(root.rippleColor.r, root.rippleColor.g, root.rippleColor.b, 0)
          }
        }
      }

      transform: Translate {
        x: -ripple.width / 2
        y: -ripple.height / 2
      }
    }
  }

  contentItem: StyledText {
    text: root.buttonText
  }
}
