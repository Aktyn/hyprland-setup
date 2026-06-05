import QtQuick
import QtQuick.Layouts

import "../../common"

Item {
  id: root

  property Component sourceComponent
  required property bool active
  property int padding: Style.sizes.spacingLarge

  property real targetWidth: loaderRoot.status === Loader.Ready ? loaderRoot.item.implicitWidth + root.padding * 2 : 128
  property real targetHeight: loaderRoot.status === Loader.Ready ? loaderRoot.item.implicitHeight + root.padding * 2 : 128

  Behavior on targetHeight {
    animation: Style.animation.elementMove.numberAnimation.createObject(this)
  }

  Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

  onActiveChanged: {
    if (root.active) {
      GlobalState.bar.mainPanel.currentContentWidth = targetWidth;
      GlobalState.bar.mainPanel.currentContentHeight = targetHeight;
    }
  }

  Loader {
    id: loaderRoot
    active: root.active || this.status === Loader.Ready
    focus: root.active
    asynchronous: true

    sourceComponent: root.sourceComponent
    anchors.fill: parent
    anchors.margins: root.padding

    onImplicitWidthChanged: {
      if (root.active) {
        GlobalState.bar.mainPanel.currentContentWidth = this.implicitWidth + root.padding * 2;
      }
    }
    onImplicitHeightChanged: {
      if (root.active) {
        GlobalState.bar.mainPanel.currentContentHeight = this.implicitHeight + root.padding * 2;
      }
    }
  }
}
