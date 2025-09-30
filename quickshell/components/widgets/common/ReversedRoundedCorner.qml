import QtQuick
import QtQuick.Shapes

import "../../../common"

Item {
  id: root

  enum CornerEnum {
    TopLeft = 1,
    TopRight = 2,
    BottomLeft = 3,
    BottomRight = 4
  }
  property int corner: ReversedRoundedCorner.CornerEnum.TopLeft // Default to TopLeft

  property int implicitSize: Style.rounding.hyprland + HyprlandInfo.general.gapsOut[0]
  property color color: Style.colors.background ?? "#fff"

  implicitWidth: this.implicitSize
  implicitHeight: this.implicitSize

  Shape {
    anchors.fill: parent
    layer.enabled: true
    layer.smooth: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      id: shapePath
      strokeWidth: 0

      fillColor: root.color
      startX: switch (root.corner) {
      case ReversedRoundedCorner.CornerEnum.TopLeft:
        return 0;
      case ReversedRoundedCorner.CornerEnum.TopRight:
        return root.implicitSize;
      case ReversedRoundedCorner.CornerEnum.BottomLeft:
        return 0;
      case ReversedRoundedCorner.CornerEnum.BottomRight:
        return root.implicitSize;
      }
      startY: switch (root.corner) {
      case ReversedRoundedCorner.CornerEnum.TopLeft:
        return 0;
      case ReversedRoundedCorner.CornerEnum.TopRight:
        return 0;
      case ReversedRoundedCorner.CornerEnum.BottomLeft:
        return root.implicitSize;
      case ReversedRoundedCorner.CornerEnum.BottomRight:
        return root.implicitSize;
      }
      PathAngleArc {
        moveToStart: false
        centerX: root.implicitSize - shapePath.startX
        centerY: root.implicitSize - shapePath.startY
        radiusX: root.implicitSize
        radiusY: root.implicitSize
        startAngle: switch (root.corner) {
        case ReversedRoundedCorner.CornerEnum.TopLeft:
          return 180;
        case ReversedRoundedCorner.CornerEnum.TopRight:
          return -90;
        case ReversedRoundedCorner.CornerEnum.BottomLeft:
          return 90;
        case ReversedRoundedCorner.CornerEnum.BottomRight:
          return 0;
        }
        sweepAngle: 90
      }
      PathLine {
        x: shapePath.startX
        y: shapePath.startY
      }
    }
  }

  // property Component numberAnimation: Component {
  //     NumberAnimation {
  //         duration: 1000
  //         easing.type: Easing.BezierSpline
  //         easing.bezierCurve: [0.34, 0.80, 0.34, 1.00, 1, 1]
  //     }
  // }

  // Behavior on implicitSize {
  //     animation: numberAnimation.createObject(this)
  // }
}
