pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../scripts/fuzzysort.js" as FuzzySort
import "../scripts/levendist.js" as Levendist

import "../common"

Singleton {
  id: root
  property real scoreThreshold: 0.2
  property list<string> entries: []
  readonly property var preparedEntries: entries.map(a => ({
        name: FuzzySort.prepare(`${a.replace(/^\s*\S+\s+/, "")}`),
        entry: a
      }))
  function fuzzyQuery(search: string): var {
    if (search.length > 5) {
      const results = entries.slice(0, 100).map(str => ({
            entry: str,
            score: Levendist.computeTextMatchScore(str.toLowerCase(), search.toLowerCase())
          })).filter(item => item.score > root.scoreThreshold).sort((a, b) => b.score - a.score);
      return results.map(item => item.entry);
    }

    return FuzzySort.go(search, preparedEntries, {
      all: true,
      key: "name"
    }).map(r => {
      return r.obj.entry;
    });
  }

  function refresh() {
    readProc.buffer = [];
    readProc.running = true;
  }

  function copy(entry) {
    Quickshell.execDetached(["bash", "-c", `echo '${Utils.shellSingleQuoteEscape(entry)}' | cliphist decode | wl-copy`]);
  }

  Process {
    id: deleteProc
    property string entry: ""
    command: ["bash", "-c", `echo '${Utils.shellSingleQuoteEscape(deleteProc.entry)}' | cliphist delete`]
    function deleteEntry(entry) {
      deleteProc.entry = entry;
      deleteProc.running = true;
      deleteProc.entry = "";
    }
    onExited: (exitCode, exitStatus) => {
      root.refresh();
    }
  }

  function deleteEntry(entry) {
    deleteProc.deleteEntry(entry);
  }

  Connections {
    target: Quickshell
    function onClipboardTextChanged() {
      delayedUpdateTimer.restart();
    }
  }

  Timer {
    id: delayedUpdateTimer
    interval: 200
    repeat: false
    onTriggered: {
      root.refresh();
    }
  }

  Process {
    id: readProc
    property list<string> buffer: []

    command: ["cliphist", "list"]

    stdout: SplitParser {
      onRead: line => {
        readProc.buffer.push(line);
      }
    }

    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        root.entries = readProc.buffer;
      } else {
        console.error("[Cliphist] Failed to refresh with code", exitCode, "and status", exitStatus);
      }
    }
  }
}
