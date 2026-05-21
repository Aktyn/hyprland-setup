hl.window_rule({ name = "rule_1", match = { class = ".*" }, opacity = "0.9" })
hl.window_rule({ name = "rule_2", match = { title = "^(Picture\\sin\\spicture)$" }, opacity = "1" })
hl.window_rule({ name = "rule_3", match = { class = "zen" }, opaque = true })
hl.window_rule({ name = "rule_4", match = { class = "gimp" }, opacity = "1" })
hl.window_rule({ name = "rule_5", match = { class = "org\\.kde\\.gwenview" }, opacity = "1" })
hl.window_rule({ name = "rule_6", match = { class = "dev\\.warp\\.Warp" }, opacity = "1" })

-- Disable blur for xwayland context menus
hl.window_rule({ name = "rule_7", match = { class = "^()$", title = "^()$" }, no_blur = true })
hl.window_rule({ name = "rule_8", match = { class = "^()$", title = "^()$" }, opacity = "1" })
hl.window_rule({ name = "rule_9", match = { fullscreen = true }, opaque = true })

-- Floating
hl.window_rule({ name = "rule_10", match = { class = "^(blueberry\\.py)$" }, float = true })
hl.window_rule({ name = "rule_11", match = { class = "^(pavucontrol)$" }, float = true })
hl.window_rule({ name = "rule_12", match = { class = "^(pavucontrol)$" }, size = "45% 45%" })
hl.window_rule({ name = "rule_13", match = { class = "^(pavucontrol)$" }, center = true })
hl.window_rule({ name = "rule_14", match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true })
hl.window_rule({ name = "rule_15", match = { class = "^(org.pulseaudio.pavucontrol)$" }, size = "45% 45%" })
hl.window_rule({ name = "rule_16", match = { class = "^(org.pulseaudio.pavucontrol)$" }, center = true })
hl.window_rule({ name = "rule_17", match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ name = "rule_18", match = { class = "^(nm-connection-editor)$" }, size = "45% 45%" })
hl.window_rule({ name = "rule_19", match = { class = "^(nm-connection-editor)$" }, center = true })
hl.window_rule({ name = "rule_20", match = { class = ".*plasmawindowed.*" }, float = true })
hl.window_rule({ name = "rule_21", match = { class = "kcm_.*" }, float = true })
hl.window_rule({ name = "rule_22", match = { class = ".*bluedevilwizard" }, float = true })
hl.window_rule({ name = "rule_23", match = { class = "^[Bb]lueman-manager$" }, float = true })
hl.window_rule({ name = "rule_24", match = { class = "^[Bb]lueman-manager$" }, center = true })
hl.window_rule({ name = "rule_25", match = { title = ".*Welcome" }, float = true })
hl.window_rule({ name = "rule_26", match = { class = "org.freedesktop.impl.portal.desktop.kde" }, float = true })
hl.window_rule({ name = "rule_27", match = { class = "^(Zotero)$" }, float = true })
hl.window_rule({ name = "rule_28", match = { class = "^(Zotero)$" }, size = "45% 45%" })
hl.window_rule({ name = "rule_29", match = { class = "^org\\.qbittorrent\\.qBittorrent$" }, float = true })
hl.window_rule({ name = "rule_30", match = { class = "^org\\.kde\\.kdialog$" }, float = true })

-- Move
-- kde-material-you-colors spawns a window when changing dark/light theme. This is to make sure it doesn't interfere at all.
hl.window_rule({ name = "rule_31", match = { class = "^(plasma-changeicons)$" }, float = true })
hl.window_rule({ name = "rule_32", match = { class = "^(plasma-changeicons)$" }, no_initial_focus = true })
hl.window_rule({ name = "rule_33", match = { class = "^(plasma-changeicons)$" }, move = "999999 999999" })
-- dolphin copy dialog
hl.window_rule({ name = "rule_34", match = { title = "^(Copying — Dolphin)$" }, move = "40 80" })

-- Tiling
hl.window_rule({ name = "rule_35", match = { class = "^dev\\.warp\\.Warp$" }, tile = true })

-- Picture-in-Picture
hl.window_rule({ name = "rule_36", match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true })
hl.window_rule({ name = "rule_37", match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, keep_aspect_ratio = true })
hl.window_rule({ name = "rule_38", match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, move = "73% 72%" })
hl.window_rule({ name = "rule_39", match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, size = "25% 25%" })
hl.window_rule({ name = "rule_40", match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, opaque = true })
hl.window_rule({ name = "rule_41", match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, pin = true })

-- Dialog windows – float+center these windows.
hl.window_rule({ name = "rule_42", match = { title = "^(Open File)(.*)$" }, center = true })
hl.window_rule({ name = "rule_43", match = { title = "^(Select a File)(.*)$" }, center = true })
hl.window_rule({ name = "rule_44", match = { title = "^(Choose wallpaper)(.*)$" }, center = true })
hl.window_rule({ name = "rule_45", match = { title = "^(Open Folder)(.*)$" }, center = true })
hl.window_rule({ name = "rule_46", match = { title = "^(Save As)(.*)$" }, center = true })
hl.window_rule({ name = "rule_47", match = { title = "^(Library)(.*)$" }, center = true })
hl.window_rule({ name = "rule_48", match = { title = "^(File Upload)(.*)$" }, center = true })
hl.window_rule({ name = "rule_49", match = { title = "^(.*)(wants to save)$" }, center = true })
hl.window_rule({ name = "rule_50", match = { title = "^(.*)(wants to open)$" }, center = true })
hl.window_rule({ name = "rule_51", match = { title = "^(Open File)(.*)$" }, float = true })
hl.window_rule({ name = "rule_52", match = { title = "^(Select a File)(.*)$" }, float = true })
hl.window_rule({ name = "rule_53", match = { title = "^(Open Folder)(.*)$" }, float = true })
hl.window_rule({ name = "rule_54", match = { title = "^(Save As)(.*)$" }, float = true })
hl.window_rule({ name = "rule_55", match = { title = "^(Library)(.*)$" }, float = true })
hl.window_rule({ name = "rule_56", match = { title = "^(File Upload)(.*)$" }, float = true })
hl.window_rule({ name = "rule_57", match = { title = "^(.*)(wants to save)$" }, float = true })
hl.window_rule({ name = "rule_58", match = { title = "^(.*)(wants to open)$" }, float = true })


-- --- Tearing ---
hl.window_rule({ name = "rule_59", match = { title = ".*\\.exe" }, immediate = true })
hl.window_rule({ name = "rule_60", match = { class = "^(steam_app).*" }, immediate = true })

-- No shadow for tiled windows (matches windows that are not floating).
hl.window_rule({ name = "rule_61", match = { float = false }, no_shadow = true })

hl.window_rule({ name = "rule_62", match = { float = true }, border_size = 0 })

-- ######## Workspace rules ########
hl.workspace_rule({  workspace = "special:special", gaps_out = 30 })

-- ######## Layer rules ########
hl.layer_rule({ name = "rule_64", match = { namespace = ".*" }, xray = true })
-- layerrule = no_anim true, match:namespace .*
hl.layer_rule({ name = "rule_65", match = { namespace = "walker" }, no_anim = true })
hl.layer_rule({ name = "rule_66", match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ name = "rule_67", match = { namespace = "overview" }, no_anim = true })
hl.layer_rule({ name = "rule_68", match = { namespace = "anyrun" }, no_anim = true })
hl.layer_rule({ name = "rule_69", match = { namespace = "indicator.*" }, no_anim = true })
hl.layer_rule({ name = "rule_70", match = { namespace = "osk" }, no_anim = true })
hl.layer_rule({ name = "rule_71", match = { namespace = "hyprpicker" }, no_anim = true })

hl.layer_rule({ name = "rule_72", match = { namespace = "noanim" }, no_anim = true })
hl.layer_rule({ name = "rule_73", match = { namespace = "gtk-layer-shell" }, blur = true })
hl.layer_rule({ name = "rule_74", match = { namespace = "gtk-layer-shell" }, ignore_alpha = 1 })
hl.layer_rule({ name = "rule_75", match = { namespace = "launcher" }, blur = true })
hl.layer_rule({ name = "rule_76", match = { namespace = "launcher" }, ignore_alpha = 0.5 })
hl.layer_rule({ name = "rule_77", match = { namespace = "notifications" }, blur = true })
hl.layer_rule({ name = "rule_78", match = { namespace = "notifications" }, ignore_alpha = 0.69 })
hl.layer_rule({ name = "rule_79", match = { namespace = "logout_dialog" }, blur = true }) -- wlogout

-- ags
hl.layer_rule({ name = "rule_80", match = { namespace = "sideleft.*" }, animation = "slide left" })
hl.layer_rule({ name = "rule_81", match = { namespace = "sideright.*" }, animation = "slide right" })
hl.layer_rule({ name = "rule_82", match = { namespace = "session[0-9]*" }, blur = true })
hl.layer_rule({ name = "rule_83", match = { namespace = "bar[0-9]*" }, blur = true })
hl.layer_rule({ name = "rule_84", match = { namespace = "bar[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ name = "rule_85", match = { namespace = "barcorner.*" }, blur = true })
hl.layer_rule({ name = "rule_86", match = { namespace = "barcorner.*" }, ignore_alpha = 0.6 })
hl.layer_rule({ name = "rule_87", match = { namespace = "dock[0-9]*" }, blur = true })
hl.layer_rule({ name = "rule_88", match = { namespace = "dock[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ name = "rule_89", match = { namespace = "indicator.*" }, blur = true })
hl.layer_rule({ name = "rule_90", match = { namespace = "indicator.*" }, ignore_alpha = 0.6 })
hl.layer_rule({ name = "rule_91", match = { namespace = "overview[0-9]*" }, blur = true })
hl.layer_rule({ name = "rule_92", match = { namespace = "overview[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ name = "rule_93", match = { namespace = "cheatsheet[0-9]*" }, blur = true })
hl.layer_rule({ name = "rule_94", match = { namespace = "cheatsheet[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ name = "rule_95", match = { namespace = "sideright[0-9]*" }, blur = true })
hl.layer_rule({ name = "rule_96", match = { namespace = "sideright[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ name = "rule_97", match = { namespace = "sideleft[0-9]*" }, blur = true })
hl.layer_rule({ name = "rule_98", match = { namespace = "sideleft[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ name = "rule_99", match = { namespace = "indicator.*" }, blur = true })
hl.layer_rule({ name = "rule_100", match = { namespace = "indicator.*" }, ignore_alpha = 0.6 })
hl.layer_rule({ name = "rule_101", match = { namespace = "osk[0-9]*" }, blur = true })
hl.layer_rule({ name = "rule_102", match = { namespace = "osk[0-9]*" }, ignore_alpha = 0.6 })

hl.layer_rule({ name = "rule_103", match = { namespace = "gtk4-layer-shell" }, no_anim = true })

hl.layer_rule({ name = "rule_104", match = { namespace = "quickshell:panel" }, blur = true })
hl.layer_rule({ name = "rule_105", match = { namespace = "quickshell:panel" }, ignore_alpha = 0.1 })
hl.layer_rule({ name = "rule_106", match = { namespace = "quickshell:panel" }, xray = false })
hl.layer_rule({ name = "rule_107", match = { namespace = "quickshell:panel" }, no_anim = true })

hl.window_rule({ name = "rule_108", match = { class = "org.quickshell", title = "^Settings$" }, float = true })
