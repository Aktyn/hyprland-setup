//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import Quickshell

import "components"
import "components/bar"
import "components/osd"

ShellRoot {
  Bar {}
  Wallpaper {}

  // --- OSDs ---
  VolumeChangeIndicator {}

  Component.onCompleted: {
    //TODO: initialize some services

    Quickshell.execDetached("sleep 1 && killall kded6 || true");

    console.info("Aktyn quickshell started");
    // Cliphist.refresh()
    // MaterialThemeLoader.reapplyTheme()
  }
}
