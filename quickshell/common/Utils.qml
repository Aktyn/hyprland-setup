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
}
