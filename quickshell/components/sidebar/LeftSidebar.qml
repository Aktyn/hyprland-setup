import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "../../scripts/levendist.js" as Levendist
import "../../scripts/md5.js" as MD5

import "../../common"
import "../widgets/common"

ColumnLayout {
  id: root

  property bool active: GlobalState.leftSidebar.open
  property real scoreThreshold: 0.2

  readonly property list<DesktopEntry> allApps: Array.from(DesktopEntries.applications.values).filter(entry => !entry.noDisplay).sort((a, b) => {
    const aIndex = Utils.recentApps.indexOf(a.name);
    const bIndex = Utils.recentApps.indexOf(b.name);
    if (aIndex === -1 && bIndex === -1) {
      return a.name.localeCompare(b.name);
    }

    return bIndex - aIndex;
  })

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
    const combinedNames = root.appsList.reduce((acc, app) => acc + app.name, "");
    this.appResultsHash = MD5.md5(combinedNames);
  }

  property string appResultsHash: ""
  onAppResultsHashChanged: function () {
    if (appSearch.searchText.startsWith("!") && appSearch.searchText.length > 1) {
      GlobalState.leftSidebar.appSearch.selectedEntryIndex = -1;
    } else {
      GlobalState.leftSidebar.appSearch.selectedEntryIndex = 0;
    }
  }

  Keys.onPressed: event => {
    if (event.key === Qt.Key_Up) {
      GlobalState.leftSidebar.appSearch.selectedEntryIndex--;
      event.accepted = true;
    } else if (event.key === Qt.Key_Down) {
      GlobalState.leftSidebar.appSearch.selectedEntryIndex++;
      event.accepted = true;
    }

    GlobalState.leftSidebar.appSearch.selectedEntryIndex = Utils.clamp(GlobalState.leftSidebar.appSearch.selectedEntryIndex, 0, this.appsList.length - 1);
  }

  onActiveChanged: {
    if (this.active) {
      if (typeof appSearch.focusInput === 'function') {
        appSearch.focusInput();
      }

      GlobalState.leftSidebar?.requestFocus();
      clearTimeout.running = false;
    } else if (typeof appSearch.clear === "function") {
      clearTimeout.restart();
    }
  }

  Timer {
    id: clearTimeout
    interval: Config.bar.panelSlideDuration
    repeat: false
    running: false
    onTriggered: {
      appSearch.clear();
    }
  }

  spacing: Style.sizes.spacingLarge

  SearchField {
    id: appSearch

    Layout.fillWidth: true
    placeholder: "Search or calculate. \"!\" to run commands"

    onEnter: function () {
      if (appSearch.searchText.startsWith("!") && appSearch.searchText.length > 1) {
        Quickshell.execDetached(["bash", "-c", appSearch.searchText.substr(1)]);
        return;
      }

      if (GlobalState.leftSidebar.appSearch.selectedEntryIndex < root.appsList.length) {
        const app = root.appsList[GlobalState.leftSidebar.appSearch.selectedEntryIndex];
        if (app) {
          app.execute();
          Utils.updateRecentApps(app.name);
        }
        GlobalState.leftSidebar.open = false;
        GlobalState.leftSidebar.requestFocus(false);
      }
    }
  }

  ActionButton {
    visible: appSearch.searchText.startsWith("!") && appSearch.searchText.length > 1
    Layout.fillWidth: true
    iconName: "terminal"
    content: "Run command (enter)"
    borderWidth: 1
    borderColor: Style.colors.outline

    onClicked: {
      Quickshell.execDetached(["bash", "-c", appSearch.searchText.substr(1)]);
      GlobalState.leftSidebar.open = false;
      GlobalState.leftSidebar.requestFocus(false);
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

  ColumnLayout {
    visible: root.noAppResults && !!root.calcResult

    Layout.fillWidth: true
    spacing: 0

    Text {
      text: root.calcResult.includes("=") ? root.calcResult : `= ${root.calcResult}`
      font.bold: true
      font.pixelSize: Style.font.pixelSize.large
      color: Style.colors.primary
    }

    ActionButton {
      Layout.fillWidth: true
      iconName: "content_copy"
      content: "Copy to clipboard"
      borderWidth: 1
      borderColor: Style.colors.outline

      onClicked: {
        const result = root.calcResult.replace(/"/g, '\\"').replace(/\n$/, "");
        ScriptRunner.copyToClipboard(result);

        GlobalState.leftSidebar.open = false;
        GlobalState.leftSidebar.requestFocus(false);
      }
    }
  }

  Text {
    visible: root.noAppResults && !root.calcResult

    Layout.fillWidth: true
    horizontalAlignment: Text.AlignHCenter
    text: "No results..."
    color: Style.colors.outlineVariant
  }
}
