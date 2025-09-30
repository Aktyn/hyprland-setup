//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import Quickshell

import "components"
import "components/bar"

ShellRoot {
  Bar {}
  Wallpaper {}

  Component.onCompleted: {
    //TODO: initialize some services
    console.info("Aktyn quickshell started");
    // Cliphist.refresh()
    // FirstRunExperience.load()
    // Hyprsunset.load()
    // MaterialThemeLoader.reapplyTheme()
  }
}
