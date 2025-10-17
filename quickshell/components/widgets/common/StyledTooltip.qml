import QtQuick
import QtQuick.Controls

import "../../../common"

ToolTip {
  id: root

  enum TooltipSide {
    Left = 1,
    Right = 2,
    Top = 3,
    Bottom = 4,
    Center = 5
  }
  property int side: StyledTooltip.TooltipSide.Bottom

  required property string content
  property bool extraVisibleCondition: true
  property bool alternativeVisibleCondition: false
  property bool internalVisibleCondition: {
    const ans = (extraVisibleCondition && (parent.hovered === undefined || parent?.hovered)) || alternativeVisibleCondition;
    return ans;
  }
  verticalPadding: Style.sizes.spacingSmall
  horizontalPadding: Style.sizes.spacingMedium
  opacity: internalVisibleCondition ? 1 : 0
  visible: opacity > 0

  Behavior on opacity {
    animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
  }

  x: switch (root.side) {
  case StyledTooltip.TooltipSide.Left:
    return -width;
  case StyledTooltip.TooltipSide.Right:
    return width;
  default:
    return Math.round((parent.width - width) / 2);
  }

  y: switch (root.side) {
  case StyledTooltip.TooltipSide.Top:
    return -parent.height;
  case StyledTooltip.TooltipSide.Bottom:
    return parent.height;
  default:
    return Math.round((parent.height - height) / 2);
  }

  background: null

  contentItem: Item {
    id: contentItemBackground
    implicitWidth: tooltipTextObject.width + 2 * root.horizontalPadding
    implicitHeight: tooltipTextObject.height + 2 * root.verticalPadding

    Rectangle {
      id: backgroundRectangle

      anchors.horizontalCenter: contentItemBackground.horizontalCenter
      anchors.verticalCenter: contentItemBackground.verticalCenter

      anchors.top: switch (root.side) {
      case StyledTooltip.TooltipSide.Bottom:
        return contentItemBackground.top;
      }
      anchors.bottom: switch (root.side) {
      case StyledTooltip.TooltipSide.Top:
        return contentItemBackground.bottom;
      }
      anchors.left: switch (root.side) {
      case StyledTooltip.TooltipSide.Right:
        return contentItemBackground.left;
      }
      anchors.right: switch (root.side) {
      case StyledTooltip.TooltipSide.Left:
        return contentItemBackground.right;
      }

      color: Style.colors.surfaceBright
      radius: Style.rounding.verysmall
      width: root.internalVisibleCondition ? (tooltipTextObject.width + 2 * root.horizontalPadding) : 0
      height: root.internalVisibleCondition ? (tooltipTextObject.height + 2 * root.verticalPadding) : 0
      clip: true

      Behavior on width {
        animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
      }
      Behavior on height {
        animation: Style.animation.elementMoveFast.numberAnimation.createObject(this)
      }

      StyledText {
        id: tooltipTextObject
        anchors.centerIn: parent
        text: root.content
        font.pixelSize: Style.font.pixelSize.smaller
        font.hintingPreference: Font.PreferNoHinting // Prevent shaky text
        color: Style.colors.colorOnSurface
        wrapMode: Text.Wrap
      }
    }
  }
}
