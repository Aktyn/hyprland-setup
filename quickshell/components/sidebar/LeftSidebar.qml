import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "../../common"

import "../widgets/common"
import "../../common"

ColumnLayout {
  id: root

  property bool active: GlobalState.leftSidebar.open

  //TODO: sort primarily according to cached list of recent apps
  readonly property list<DesktopEntry> allApps: Array.from(DesktopEntries.applications.values).filter(entry => !entry.noDisplay).sort((a, b) => a.name.localeCompare(b.name))

  readonly property list<DesktopEntry> appsList: {
    if (appSearch.searchText.length < 2) {
      return allApps;
    }

    const search = appSearch.searchText.toLowerCase();
    return allApps.filter(app => Utils.fuzzysearch(search, app.name.toLowerCase()));
  }

  onAppsListChanged: {
    GlobalState.leftSidebar.appSearch.selectedEntryIndex = 0;
  }

  Keys.onPressed: event => {
    if (event.key === Qt.Key_Up) {
      GlobalState.leftSidebar.appSearch.selectedEntryIndex = Math.max(0, GlobalState.leftSidebar.appSearch.selectedEntryIndex - 1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Down) {
      GlobalState.leftSidebar.appSearch.selectedEntryIndex = Math.min(this.appsList.length - 1, GlobalState.leftSidebar.appSearch.selectedEntryIndex + 1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      if (GlobalState.leftSidebar.appSearch.selectedEntryIndex < this.appsList.length) {
        const app = this.appsList[GlobalState.leftSidebar.appSearch.selectedEntryIndex];
        app.launch();
        GlobalState.leftSidebar.open = false;
      }
      event.accepted = true;
    }
  }

  onActiveChanged: {
    if (this.active) {
      if (typeof appSearch.focusInput === 'function') {
        appSearch.focusInput();
      }

      GlobalState.leftSidebar?.requestFocus();
    } else if (typeof appSearch.clear === "function") {
      appSearch.clear(); //TODO: add some delay to wait for panel to fully hide
    }
  }

  spacing: Style.sizes.spacingLarge

  SearchField {
    id: appSearch

    Layout.fillWidth: true
    placeholder: "Search applications"

    onEnter: function () {
      if (GlobalState.leftSidebar.appSearch.selectedEntryIndex < root.appsList.length) {
        root.appsList[GlobalState.leftSidebar.appSearch.selectedEntryIndex].execute();
        GlobalState.leftSidebar.open = false;
        GlobalState.leftSidebar.requestFocus(false);
      }
    }
  }

  Text {
    visible: root.appsList.length === 0

    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: "No search results"
    color: Style.colors.outlineVariant
  }

  ScrollView {
    visible: root.appsList.length > 0

    Layout.fillWidth: true
    Layout.maximumHeight: 640
    clip: true

    ListView {
      id: listView

      Layout.fillWidth: true
      spacing: Style.sizes.spacingSmall
      model: root.appsList
      currentIndex: GlobalState.leftSidebar.appSearch.selectedEntryIndex

      onCurrentIndexChanged: {
        if (GlobalState.leftSidebar.appSearch.selectedEntryIndex !== currentIndex) {
          GlobalState.leftSidebar.appSearch.selectedEntryIndex = currentIndex;
        }
      }

      delegate: EntryItem {
        anchors.left: parent?.left
        anchors.right: parent?.right

        entry: modelData
        toggled: GlobalState.leftSidebar.appSearch.selectedEntryIndex === index
      }
    }
  }
}
