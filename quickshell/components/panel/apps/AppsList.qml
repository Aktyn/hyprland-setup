import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "../../../common"
import "."

ScrollView {
  id: root

  required property list<DesktopEntry> apps
  clip: true

  ListView {
    id: listView

    Layout.fillWidth: true
    spacing: Style.sizes.spacingSmall
    model: root.apps
    currentIndex: GlobalState.bar.mainPanel.appSearch.selectedEntryIndex

    delegate: EntryItem {
      required property int index
      required property DesktopEntry modelData

      anchors.left: parent?.left
      anchors.right: parent?.right

      entry: modelData
      toggled: GlobalState.bar.mainPanel.appSearch.selectedEntryIndex === index
    }
  }
}
