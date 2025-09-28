import QtQuick
import QtQuick.Layouts

Item {
  id: root
  height: parent.height

  default property alias items: rowLayout.children
  property bool mirror: false
  property bool stretch: false

  RowLayout {
    id: rowLayout
    spacing: 8

    LayoutMirroring.enabled: mirror

    anchors {
      top: parent.top
      bottom: parent.bottom
      left: root.mirror || root.stretch ? parent.left : undefined
      right: root.stretch ? parent.right : undefined
    }
  }
}
