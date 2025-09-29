import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import "../../../common"

ToolTip {
  id: root

  property string content
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

  background: null

  contentItem: Item {
    id: contentItemBackground
    implicitWidth: tooltipTextObject.width + 2 * root.horizontalPadding
    implicitHeight: tooltipTextObject.height + 2 * root.verticalPadding

    Rectangle {
      id: backgroundRectangle
      anchors.top: contentItemBackground.top
      anchors.horizontalCenter: contentItemBackground.horizontalCenter
      // anchors.verticalCenter: contentItemBackground.verticalCenter
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
