import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../../scripts/levendist.js" as Levendist

import "../../common"
import "../widgets/common"

ColumnLayout {
  id: root

  property bool active: GlobalState.leftSidebar.open
  property real scoreThreshold: 0.2

  readonly property list<DesktopEntry> allApps: Array.from(DesktopEntries.applications.values).filter(entry => !entry.noDisplay).sort((a, b) => a.name.localeCompare(b.name))

  readonly property list<DesktopEntry> appsList: {
    if (appSearch.searchText.length < 1) {
      return allApps;
    }

    const search = appSearch.searchText.toLowerCase();

    const results = allApps.map(obj => ({
          entry: obj,
          score: Levendist.computeScore(obj.name.toLowerCase(), search)
        })).filter(item => item.score > root.scoreThreshold).sort((a, b) => b.score - a.score);

    return results.map(item => item.entry);
  }
  property bool noAppResults: !!appSearch.searchText && !root.appsList.length
  property string calcResult: ""

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
    placeholder: "Multi purpose input. Run commands with !"

    onEnter: function () {
      if (GlobalState.leftSidebar.appSearch.selectedEntryIndex < root.appsList.length) {
        root.appsList[GlobalState.leftSidebar.appSearch.selectedEntryIndex]?.execute();
        GlobalState.leftSidebar.open = false;
        GlobalState.leftSidebar.requestFocus(false);
      }
    }
  }

  ActionButton {
    visible: appSearch.searchText.startsWith("!") && appSearch.searchText.length > 1
    Layout.fillWidth: true
    iconName: "terminal"
    content: "Run command"
    borderWidth: 1
    borderColor: Style.colors.outline

    onClicked: {
      Quickshell.execDetached(["bash", "-c", appSearch.searchText.substr(1)]);
      GlobalState.leftSidebar.open = false;
    }
  }

  AppsList {
    visible: root.appsList.length > 0
    Layout.fillWidth: true
    Layout.maximumHeight: 640

    apps: root.appsList
  }

  Process {
    id: mathProcess
    running: false
    command: ["qalc", "-t", appSearch.searchText]

    onCommandChanged: {
      if (root.noAppResults) {
        mathProcess.running = true;
      } else {
        root.calcResult = "";
      }
    }

    stdout: StdioCollector {
      onStreamFinished: {
        root.calcResult = this.text;
      }
    }
  }

  Text {
    visible: root.noAppResults && !!root.calcResult

    Layout.fillWidth: true
    text: root.calcResult.includes("=") ? root.calcResult : `= ${root.calcResult}`
    font.bold: true
    font.pixelSize: Style.font.pixelSize.large
    color: Style.colors.primary
  }

  //TODO: transform this into custom command executor
  Text {
    visible: root.noAppResults && !root.calcResult

    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: "No results..."
    color: Style.colors.outlineVariant
  }
}
