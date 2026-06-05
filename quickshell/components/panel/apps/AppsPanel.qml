import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import "."
import "../../../scripts/levendist.js" as Levendist
import "../../../scripts/md5.js" as MD5
import "../../../common"
import "../../widgets/common"


ColumnLayout {
  id: root

  property bool active: GlobalState.bar.mainPanel.open && GlobalState.bar.mainPanel.mainPanelTabIndex === 0
  property real scoreThreshold: 0.2


  readonly property list<DesktopEntry> allApps: Array.from(DesktopEntries.applications.values).filter(entry => !entry.noDisplay).sort((a, b) => {
    const aIndex = Utils.recentApps.indexOf(a.name);
    const bIndex = Utils.recentApps.indexOf(b.name);
    if (aIndex === -1 && bIndex === -1) {
      return a.name.localeCompare(b.name);
    }

    return bIndex - aIndex;
  })

  readonly property list<var> appsList: {
    function splitList(list) {
      const listOfPairs = []
      for(let i = 0; i < list.length; i += 2) {
        listOfPairs.push({ 
          left: list[i]?.entry || list[i],
          right: list[i + 1]?.entry || list[i + 1]
        })
      }
      return listOfPairs;
    }

    if (appSearch.searchText.length < 1) {
      return splitList(allApps);
    }

    const search = appSearch.searchText.toLowerCase();

    const results = allApps.reduce((acc, entry) => {
      const score = Levendist.computeScore(entry.name.toLowerCase(), search);
      if (score > root.scoreThreshold) {
        acc.push({
          entry,
          score
        });
      }

      return acc;
    }, []).sort((a, b) => b.score - a.score);

    return splitList(results);
  }

  readonly property int appsListCount: root.appsList.length * 2 - (root.appsList[root.appsList.length-1]?.right ? 0 : 1);

  property bool noAppResults: !!appSearch.searchText && appsListCount <= 0
  property string calcResult: ""

  onAppsListChanged: {
    const combinedNames = root.appsList.reduce((acc, app) => acc + (app.left?.name || "") + (app.right?.name || ""), "");
    this.appResultsHash = MD5.md5(combinedNames);
  }

  property string appResultsHash: ""
  onAppResultsHashChanged: function () {
    if (appSearch.searchText.startsWith("!") && appSearch.searchText.length > 1) {
      GlobalState.bar.mainPanel.appSearch.selectedEntryIndex = -1;
    } else {
      GlobalState.bar.mainPanel.appSearch.selectedEntryIndex = 0;
    }
  }

  Keys.onPressed: event => {
    if (event.key === Qt.Key_Up) {
      GlobalState.bar.mainPanel.appSearch.selectedEntryIndex--;
      event.accepted = true;
    } else if (event.key === Qt.Key_Down) {
      GlobalState.bar.mainPanel.appSearch.selectedEntryIndex++;
      event.accepted = true;
    }

    GlobalState.bar.mainPanel.appSearch.selectedEntryIndex = Utils.clamp(GlobalState.bar.mainPanel.appSearch.selectedEntryIndex, 0, this.appsListCount - 1);
  }

  onActiveChanged: {
    if (this.active) {
      if (typeof appSearch.focusInput === 'function') {
        appSearch.focusInput();
      }

      GlobalState.bar.mainPanel?.requestFocus();
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

  function runCommand(command: string) {
    console.info("Executing command: " + command);
    Quickshell.execDetached(["bash", "-c", command]);
    GlobalState.bar.mainPanel.open = false;
    GlobalState.bar.mainPanel.requestFocus(false);
  }

  SearchField {
    id: appSearch

    Layout.fillWidth: true
    placeholder: "Search or calculate. \"!\" to run commands"

    onEnter: function () {
      if (appSearch.searchText.startsWith("!") && appSearch.searchText.length > 1) {
        root.runCommand(appSearch.searchText.substr(1));
        return;
      }

      if (GlobalState.bar.mainPanel.appSearch.selectedEntryIndex < root.appsListCount) {
        const appsPair = root.appsList[Math.floor(GlobalState.bar.mainPanel.appSearch.selectedEntryIndex/2)];
        const entry = GlobalState.bar.mainPanel.appSearch.selectedEntryIndex % 2 === 0 ? appsPair.left : appsPair.right;
        if (entry) {
          entry.execute();
          Utils.updateRecentApps(entry.name);
        }
        GlobalState.bar.mainPanel.open = false;
        GlobalState.bar.mainPanel.requestFocus(false);
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
      root.runCommand(appSearch.searchText.substr(1));
    }
  }

  AppsList {
    visible: root.appsListCount > 0
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

        GlobalState.bar.mainPanel.open = false;
        GlobalState.bar.mainPanel.requestFocus(false);
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
