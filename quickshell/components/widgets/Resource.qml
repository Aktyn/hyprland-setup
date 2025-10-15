import QtQuick
import QtQuick.Layouts

import "../../common"
import "."
import "./common"

Item {
  id: root

  required property string iconName
  required property double percentage
  property bool shown: true
  clip: true
  visible: width > 0 && height > 0
  implicitWidth: resourceRowLayout.x < 0 ? 0 : childrenRect.width
  implicitHeight: childrenRect.height

  RowLayout {
    id: resourceRowLayout
    spacing: 4
    x: root.shown ? 0 : -resourceRowLayout.width

    CircularProgress {
      Layout.alignment: Qt.AlignVCenter
      lineWidth: 2
      value: root.percentage
      implicitSize: Style.sizes.heightLarge
      colPrimary: Style.colors.colorOnSecondaryContainer
      enableAnimation: false

      MaterialSymbol {
        anchors.centerIn: parent

        text: root.iconName
        iconSize: Style.font.pixelSize.normal
        color: Style.colors.colorOnSecondaryContainer
      }
    }

    StyledText {
      Layout.alignment: Qt.AlignVCenter
      color: Style.colors.colorOnSurface
      text: `${Math.round(root.percentage * 100) < 10 ? " " : ""}${Math.round(root.percentage * 100)}%`
    }

    Behavior on x {
      animation: Style.animation.elementMove.numberAnimation.createObject(this)
    }
  }

  Behavior on implicitWidth {
    animation: Style.animation.elementMove.numberAnimation.createObject(this)
  }
}
