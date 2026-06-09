import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../../../common"
import "."

ScrollView {
  id: root

  required property list<var> apps
  clip: true


  ListView {
    id: listView

    Layout.fillWidth: true
    spacing: Style.sizes.spacingMedium
    model: root.apps
    currentIndex: GlobalState.bar.mainPanel.appSearch.selectedEntryIndex

    delegate: Grid {
      id: row
      required property int index
      required property var modelData

      Layout.fillWidth: true
      columns: 2
      spacing: Style.sizes.spacingMedium

      anchors.left: parent?.left
      anchors.right: parent?.right

      ListEntry {
        visible: !!row.modelData.left

        width: (row.width - row.spacing) / 2
        entry: row.modelData.left
        toggled: listView.currentIndex === row.index*2
      }

      ListEntry {
        visible: !!row.modelData.right

        width: (row.width - row.spacing) / 2
        entry: row.modelData.right ?? null
        toggled: listView.currentIndex === row.index*2+1
      }
    }
  }

  component ListEntry: EntryItem {
    borderWidth: 1
    borderColor: hovered ? Style.colors.outline : (toggled ? Style.colors.primary : "transparent")
  }
}
