pragma Singleton

import QtQuick
import Quickshell

import qs.common

Singleton {
  property bool ready: false

  onReadyChanged: {
    if (ready) {
      if (Config.wallpaper.path && Config.wallpaper.path !== Style.wallpaper) {
        ScriptRunner.generateMaterialYouColors(Config.wallpaper.path);
      }
    }
  }

  /**
   * Transparentize a color by a given percentage
   * @param {string} color
   * @param {number} alpha
   * @returns {Qt.rgba}
   */
  function transparentize(color, alpha = 1) {
    var c = Qt.color(color);
    return Qt.rgba(c.r, c.g, c.b, c.a * alpha);
  }
}
