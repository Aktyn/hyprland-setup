//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import Quickshell
import Quickshell.Hyprland

import "components"
import "components/bar"
import "components/osd"

import "common"

ShellRoot {
  Bar {}
  Wallpaper {}

  // --- OSDs ---
  VolumeChangeIndicator {}

  //TODO: [optimization] create generic component for automatically unloading lazy loaded components
  LazyLoader {
    loading: GlobalState.osd.cheetsheetOpen
    component: Cheetsheet {}
  }
  LazyLoader {
    loading: GlobalState.osd.clipboardPanelOpen
    component: ClipboardHistoryPanel {}
  }

  Component.onCompleted: {
    Hyprland.dispatch(`hl.dsp.exec_cmd("killall kded6")`);

    console.info("Aktyn quickshell started");
  }
}
