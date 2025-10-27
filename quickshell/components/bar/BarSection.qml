import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../../common"

Item {
  id: root
  property bool mirror: false
  property bool stretch: false
  default property alias items: rowLayout.children

  Layout.fillWidth: true
  Layout.fillHeight: true

  ScrollView {
    id: scrollView

    anchors.fill: parent
    anchors.leftMargin: root.mirror ? -Style.sizes.spacingLarge : 0
    anchors.rightMargin: !root.mirror ? -Style.sizes.spacingLarge : 0

    ScrollBar.vertical.policy: ScrollBar.AlwaysOff
    ScrollBar.horizontal.policy: ScrollBar.AsNeeded

    contentWidth: Math.max(parent.width, rowLayout.implicitWidth + Style.sizes.spacingLarge)

    property var flickable: scrollView.contentItem

    NumberAnimation {
      id: scrollAnimation
      target: scrollView.flickable
      property: "contentX"
      duration: 200
      easing.type: Easing.OutQuad
    }

    MouseArea {
      anchors.fill: parent
      onWheel: wheel => {
        if (wheel.angleDelta.y !== 0) {
          const scrollAmount = wheel.angleDelta.y * 2;
          let targetX = scrollView.flickable.contentX - scrollAmount;

          const maxX = scrollView.flickable.contentWidth - scrollView.width;
          targetX = Math.max(0, Math.min(targetX, maxX));

          scrollAnimation.to = targetX;
          scrollAnimation.start();

          wheel.accepted = true;
        }
      }
    }

    RowLayout {
      id: rowLayout

      anchors {
        top: parent.top
        bottom: parent.bottom
        left: root.mirror || root.stretch ? parent.left : undefined
        right: root.stretch ? parent.right : undefined
        leftMargin: !root.mirror ? Style.sizes.spacingLarge : 0
        rightMargin: root.mirror ? Style.sizes.spacingLarge : 0
      }
      spacing: Style.sizes.spacingMedium

      LayoutMirroring.enabled: root.mirror
    }
  }
}
