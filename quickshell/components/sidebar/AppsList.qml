import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "../../common"

ScrollView {
  id: root

  required property list<DesktopEntry> apps

  ListView {
    id: listView

    Layout.fillWidth: true
    spacing: Style.sizes.spacingSmall
    model: root.apps
    currentIndex: GlobalState.leftSidebar.appSearch.selectedEntryIndex

    // onCurrentIndexChanged: {
    //   if (GlobalState.leftSidebar.appSearch.selectedEntryIndex !== currentIndex) {
    //     GlobalState.leftSidebar.appSearch.selectedEntryIndex = currentIndex;
    //   }
    // }

    delegate: EntryItem {
      anchors.left: parent?.left
      anchors.right: parent?.right

      entry: modelData
      toggled: GlobalState.leftSidebar.appSearch.selectedEntryIndex === index
    }
  }
}
