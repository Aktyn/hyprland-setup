import QtQuick
import QtQuick.Layouts

Item {
  id: root
  height: parent.height

  default property alias items: rowLayout.children
  // property QQuickAnchorLine rightAnchor: QQuickAnchorLine.right
  property bool mirror: false

  RowLayout {
    id: rowLayout
    spacing: 8

    LayoutMirroring.enabled: mirror

    anchors {
      top: parent.top
      bottom: parent.bottom
      left: root.mirror ? parent.left : undefined
      // right: root.mirror ? parent.right : undefined
    }
  }
}
