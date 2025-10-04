pragma Singleton

import QtQuick
import Quickshell

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
}
