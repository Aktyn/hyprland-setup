//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import Quickshell

import "components"
import "components/bar"

ShellRoot {
  Bar {}
  Wallpaper {}
}
