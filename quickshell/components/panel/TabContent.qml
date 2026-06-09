import QtQuick
import QtQuick.Layouts

import "../../common"

Item {
  id: root

  property Component sourceComponent
  required property bool focused
  property int padding: Style.sizes.spacingLarge

  property real targetWidth: loaderRoot.status === Loader.Ready ? loaderRoot.item.implicitWidth + root.padding * 2 : 128
  property real targetHeight: loaderRoot.status === Loader.Ready ? loaderRoot.item.implicitHeight + root.padding * 2 : 128

  Behavior on targetHeight {
    animation: Style.animation.elementMove.numberAnimation.createObject(this)
  }

  Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

  onFocusedChanged: {
    if (root.focused) {
      GlobalState.bar.mainPanel.currentContentWidth = targetWidth;
      GlobalState.bar.mainPanel.currentContentHeight = targetHeight;
    }
  }
 
  Loader {
    id: loaderRoot
    active: root.focused || this.status === Loader.Ready
    asynchronous: true
    focus: root.focused

    sourceComponent: root.sourceComponent
    anchors.fill: parent
    anchors.margins: root.padding

    onImplicitWidthChanged: {
      if (root.focused) {
        GlobalState.bar.mainPanel.currentContentWidth = this.implicitWidth + root.padding * 2;
      }
    }
    onImplicitHeightChanged: {
      if (root.focused) {
        GlobalState.bar.mainPanel.currentContentHeight = this.implicitHeight + root.padding * 2;
      }
    }
  }
}
