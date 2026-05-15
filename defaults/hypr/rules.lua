-- Window Rules
hl.window_rule({ match = { class = ".*" }, opacity = 0.9 })
hl.window_rule({ match = { title = "^(Picture\\sin\\spicture)$" }, opacity = 1 })
hl.window_rule({ match = { class = "zen" }, opaque = true })
hl.window_rule({ match = { class = "gimp" }, opacity = 1 })
hl.window_rule({ match = { class = "org\\.kde\\.gwenview" }, opacity = 1 })
hl.window_rule({ match = { class = "dev\\.warp\\.Warp" }, opacity = 1 })

-- Disable blur for xwayland context menus
hl.window_rule({ match = { class = "^()$", title = "^()$" }, no_blur = true, opacity = 1 })
hl.window_rule({ match = { fullscreen = true }, opaque = true })

-- Floating
hl.window_rule({ match = { class = "^(blueberry\\.py)$" }, float = true })
hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true, size = "45% 45%", center = true })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true, size = "45% 45%", center = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true, size = "45% 45%", center = true })
hl.window_rule({ match = { class = ".*plasmawindowed.*" }, float = true })
hl.window_rule({ match = { class = "kcm_.*" }, float = true })
hl.window_rule({ match = { class = ".*bluedevilwizard" }, float = true })
hl.window_rule({ match = { class = "^[Bb]lueman-manager$" }, float = true, center = true })
hl.window_rule({ match = { title = ".*Welcome" }, float = true })
hl.window_rule({ match = { class = "org.freedesktop.impl.portal.desktop.kde" }, float = true })
hl.window_rule({ match = { class = "^(Zotero)$" }, float = true, size = "45% 45%" })
hl.window_rule({ match = { class = "^org\\.qbittorrent\\.qBittorrent$" }, float = true })
hl.window_rule({ match = { class = "^org\\.kde\\.kdialog$" }, float = true })

-- Move
hl.window_rule({ match = { class = "^(plasma-changeicons)$" }, float = true, no_initial_focus = true, move = "999999 999999" })
hl.window_rule({ match = { title = "^(Copying — Dolphin)$" }, move = "40 80" })

-- Tiling
hl.window_rule({ match = { class = "^dev\\.warp\\.Warp$" }, tile = true })

-- Picture-in-Picture
local pip_match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }
hl.window_rule({ match = pip_match, float = true, keep_aspect_ratio = true, move = "73% 72%", size = "25% 25%", opaque = true, pin = true })

-- Dialog windows
local dialog_titles = { "^(Open File)(.*)$", "^(Select a File)(.*)$", "^(Choose wallpaper)(.*)$", "^(Open Folder)(.*)$", "^(Save As)(.*)$", "^(Library)(.*)$", "^(File Upload)(.*)$", "^(.*)(wants to save)$", "^(.*)(wants to open)$" }
for _, title in ipairs(dialog_titles) do
    hl.window_rule({ match = { title = title }, float = true, center = true })
end

-- Tearing
hl.window_rule({ match = { title = ".*\\.exe" }, immediate = true })
hl.window_rule({ match = { class = "^(steam_app).*" }, immediate = true })

-- No shadow for tiled windows
hl.window_rule({ match = { float = false }, no_shadow = true })
hl.window_rule({ match = { float = true }, border_size = 0 })

-- Workspace rules
-- TODO: fix
-- hl.workspace_rule({ workspace = "special:special", gapsout = 30 })

-- Layer rules
hl.layer_rule({ match = { namespace = ".*" }, xray = true })

local no_anim_namespaces = { "walker", "selection", "overview", "anyrun", "indicator.*", "osk", "hyprpicker", "noanim", "quickshell:panel" }
for _, ns in ipairs(no_anim_namespaces) do
    hl.layer_rule({ match = { namespace = ns }, no_anim = true })
end

hl.layer_rule({ match = { namespace = "gtk-layer-shell" }, blur = true, ignore_alpha = 1 })
hl.layer_rule({ match = { namespace = "launcher" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true, ignore_alpha = 0.69 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true })

-- ags
hl.layer_rule({ match = { namespace = "sideleft.*" }, animation = "slide left" })
hl.layer_rule({ match = { namespace = "sideright.*" }, animation = "slide right" })

local blur_namespaces = { "session[0-9]*", "bar[0-9]*", "barcorner.*", "dock[0-9]*", "indicator.*", "overview[0-9]*", "cheatsheet[0-9]*", "sideright[0-9]*", "sideleft[0-9]*", "osk[0-9]*" }
for _, ns in ipairs(blur_namespaces) do
    hl.layer_rule({ match = { namespace = ns }, blur = true, ignore_alpha = 0.6 })
end

hl.layer_rule({ match = { namespace = "gtk4-layer-shell" }, blur = false }) -- Implicitly no blur if not specified, but let's keep it consistent
hl.layer_rule({ match = { namespace = "quickshell:panel" }, blur = true, ignore_alpha = 0.1, xray = false })

hl.window_rule({ match = { class = "org.quickshell", title = "^Settings$" }, float = true })
