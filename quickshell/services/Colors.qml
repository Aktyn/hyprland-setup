pragma Singleton

import QtQuick
import Quickshell

import "../common"

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
   * Transparentizes a color by a given percentage
   * @param {string} color
   * @param {number} alpha
   * @returns {Qt.rgba}
   */
  function transparentize(color, alpha = 1) {
    var c = Qt.color(color);
    return Qt.rgba(c.r, c.g, c.b, c.a * alpha);
  }
}
