pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  /**
    * Removes "file://" from the beginning of given string
    * @param {string} str
    * @returns {string}
    */
  function trimFileProtocol(str) {
    return str.startsWith("file://") ? str.slice(7) : str;
  }

  /**
    * Escapes single quotes in shell commands
    * @param { string } str
    * @returns { string }
    */
  function shellSingleQuoteEscape(str) {
    //  escape single quotes
    return String(str)
    // .replace(/\\/g, '\\\\')
    .replace(/'/g, "'\\''");
  }

  /**
    * @param {string} needle
    * @param {string} haystack
    * @returns {boolean}
    */
  function fuzzysearch(needle, haystack) {
    if (needle === "") {
      return true;
    }
    if (haystack === "") {
      return false;
    }

    var hlen = haystack.length;
    var nlen = needle.length;
    if (nlen > hlen) {
      return false;
    }
    if (nlen === hlen) {
      return needle === haystack;
    }
    outer: for (var i = 0, j = 0; i < nlen; i++) {
      var nch = needle.charCodeAt(i);
      while (j < hlen) {
        if (haystack.charCodeAt(j++) === nch) {
          continue outer;
        }
      }
      return false;
    }
    return true;
  }

  property alias recentApps: recentAppsJsonAdapter.apps
  FileView {
    path: Consts.path.recentAppsFile
    watchChanges: true

    onFileChanged: {
      reload();
    }

    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound) {
        writeAdapter();
        reload();
      }
    }

    JsonAdapter {
      id: recentAppsJsonAdapter

      property list<string> apps: []
    }
  }

  readonly property int recentAppsHistorySize: 128
  function updateRecentApps(appName: string) {
    this.recentApps = [...this.recentApps.filter(app => app !== appName), appName].slice(-this.recentAppsHistorySize);
  }

  function cleanMusicTitle(title: string): string {
    if (!title) {
      return "";
    }

    // Brackets
    title = title.replace(/^ *\([^)]*\) */g, " ");
    title = title.replace(/^ *\[[^\]]*\] */g, " ");
    title = title.replace(/^ *\{[^\}]*\} */g, " ");
    title = title.replace(/^ *【[^】]*】/, "");
    title = title.replace(/^ *《[^》]*》/, "");
    title = title.replace(/^ *「[^」]*」/, "");
    title = title.replace(/^ *『[^』]*』/, "");

    return title.trim();
  }

  function friendlyTimeForSeconds(seconds: int): string {
    if (isNaN(seconds) || seconds < 0)
      return "0:00";
    seconds = Math.floor(seconds);
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;
    if (h > 0) {
      return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    } else {
      return `${m}:${s.toString().padStart(2, '0')}`;
    }
  }

  function clamp(value: real, min: real, max: real): real {
    return Math.max(min, Math.min(max, value));
  }
}
