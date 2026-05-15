-- Config customized by Aktyn
-- https://github.com/Aktyn/hyprland-setup

-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/

hl.config({
    debug = {
        disable_logs = false
    }
})

require("env")
require("general")
require("execs")
require("rules")
require("keybinds")
require("dynamic")
require("hdr")
require("custom")
