local scripts_dir = os.getenv("HOME") .. "/.config/hypr/scripts/"
local workspace_action = scripts_dir .. "workspace_action.sh"
local launch_first_available = scripts_dir .. "launch_first_available.sh"
local player_next =
	'playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"`'

hl.bind("SUPER + SUPER_L", hl.dsp.global("quickshell:overviewToggleRelease"), { release = true }) -- Original bind: Super, Super_L, Toggle overview, global, quickshell:overviewToggleRelease
hl.bind("SUPER + SUPER_R", hl.dsp.global("quickshell:overviewToggleRelease"), { release = true }) -- Original bind: Super, Super_R, Toggle overview, global, quickshell:overviewToggleRelease

-- 	hl.bind("SUPER + catchall", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- Original bind: Super, catchall, global, quickshell:overviewToggleReleaseInterrupt
hl.bind("CTRL + SUPER_L", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- Original bind: Ctrl, Super_L, global, quickshell:overviewToggleReleaseInterrupt
hl.bind("CTRL + SUPER_R", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- Original bind: Ctrl, Super_R, global, quickshell:overviewToggleReleaseInterrupt
hl.bind("SUPER + mouse:272", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), { mouse = true }) -- Original bind: Super, mouse:272, global, quickshell:overviewToggleReleaseInterrupt
hl.bind("SUPER + mouse:273", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), { mouse = true }) -- Original bind: Super, mouse:273, global, quickshell:overviewToggleReleaseInterrupt
hl.bind("SUPER + mouse:274", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), { mouse = true }) -- Original bind: Super, mouse:274, global, quickshell:overviewToggleReleaseInterrupt
hl.bind("SUPER + mouse:275", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), { mouse = true }) -- Original bind: Super, mouse:275, global, quickshell:overviewToggleReleaseInterrupt
hl.bind("SUPER + mouse:276", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), { mouse = true }) -- Original bind: Super, mouse:276, global, quickshell:overviewToggleReleaseInterrupt
hl.bind("SUPER + mouse:277", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), { mouse = true }) -- Original bind: Super, mouse:277, global, quickshell:overviewToggleReleaseInterrupt
hl.bind("SUPER + mouse_up", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- Original bind: Super, mouse_up,  global, quickshell:overviewToggleReleaseInterrupt
hl.bind("SUPER + mouse_down", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt")) -- Original bind: Super, mouse_down,global, quickshell:overviewToggleReleaseInterrupt

hl.bind("SUPER + V", hl.dsp.global("quickshell:overviewClipboardToggle")) -- Original bind: Super, V, Clipboard history >> clipboard, global, quickshell:overviewClipboardToggle

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+"),
	{ locked = true, ["repeat"] = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),
	{ locked = true, ["repeat"] = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), { locked = true })
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), { locked = true }) -- Toggle mute
hl.bind("ALT + XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true }) -- Toggle mic

hl.bind("CTRL + SUPER + R", hl.dsp.exec_cmd("killall ags agsv1 gjs qs quickshell; qs -c aktyn &"))
hl.bind(
	"SUPER + SHIFT + S",
	hl.dsp.exec_cmd("pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent")
) -- Screen snip
hl.bind(
	"SUPER + SHIFT + T",
	hl.dsp.exec_cmd('grim -g "$(slurp $SLURP_ARGS)" "tmp.png" && tesseract "tmp.png" - | wl-copy && rm "tmp.png"')
) -- Character recognition
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a")) -- Color picker
hl.bind(
	"PRINT",
	hl.dsp.exec_cmd("grim -c -o \"$(hyprctl activeworkspace -j | jq -r '.monitor')\" - | wl-copy"),
	{ locked = true }
) -- Screenshot >> clipboard

-- Mouse window management
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:274", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Focus movement
hl.bind("SUPER + Left", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "r" }))
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + BracketLeft", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + BracketRight", hl.dsp.focus({ direction = "r" }))

-- Window movement
hl.bind("SUPER + SHIFT + Left", hl.dsp.window.move({ direction = "l" }))
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.move({ direction = "r" }))
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.move({ direction = "u" }))
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.move({ direction = "d" }))

-- Window control
hl.bind("ALT + F4", hl.dsp.window.kill())
hl.bind("SUPER + Q", hl.dsp.window.kill())
hl.bind("SUPER + SHIFT + ALT + Q", hl.dsp.exec_cmd("hyprctl kill"))

hl.bind("SUPER + SEMICOLON", hl.dsp.layout("splitratio -0.1")) -- Original bind: Super, Semicolon, layoutmsg, splitratio, -0.1
hl.bind("SUPER + APOSTROPHE", hl.dsp.layout("splitratio +0.1")) -- Original bind: Super, Apostrophe, layoutmsg, splitratio, +0.1
hl.bind("SUPER + J", hl.dsp.layout("togglesplit")) -- Original bind: Super, J, layoutmsg, togglesplit

hl.bind("SUPER + ALT + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SPACE", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + D", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })) -- Maximize
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })) -- Fullscreen
hl.bind("SUPER + ALT + F", hl.dsp.window.fullscreen_state({ internal = 3, client = 0, action = "toggle" })) -- Fullscreen, Original bind: Super+Alt, F, fullscreenstate, 0 3
hl.bind("SUPER + P", hl.dsp.window.pin())

for i = 1, 10 do
	local key = i % 10
	hl.bind("SUPER + ALT + " .. key, hl.dsp.exec_cmd(workspace_action .. " movetoworkspacesilent " .. i))
	hl.bind("SUPER + " .. key, hl.dsp.exec_cmd(workspace_action .. " workspace " .. i))
end

hl.bind("SUPER + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("SUPER + SHIFT + mouse_up", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind("SUPER + ALT + mouse_down", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("SUPER + ALT + mouse_up", hl.dsp.window.move({ workspace = "+1" }))
hl.bind("SUPER + ALT + Page_Down", hl.dsp.window.move({ workspace = "+1" }))
hl.bind("SUPER + ALT + Page_Up", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("SUPER + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind("SUPER + SHIFT + Page_Up", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("CTRL + SUPER + SHIFT + RIGHT", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind("CTRL + SUPER + SHIFT + LEFT", hl.dsp.window.move({ workspace = "r-1" }))

hl.bind("ALT + Tab", function()
	hl.dispatch(hl.dsp.window.cycle_next())
	hl.dispatch(hl.dsp.window.bring_to_top())
end)

hl.bind("CTRL + SUPER + RIGHT", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("CTRL + SUPER + LEFT", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("CTRL + SUPER + ALT + RIGHT", hl.dsp.focus({ workspace = "m+1" }))
hl.bind("CTRL + SUPER + ALT + LEFT", hl.dsp.focus({ workspace = "m-1" }))
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "+1" }))
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "-1" }))
hl.bind("CTRL + SUPER + Page_Down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("CTRL + SUPER + Page_Up", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "+1" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "-1" }))
hl.bind("CTRL + SUPER + mouse_up", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("CTRL + SUPER + mouse_down", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("CTRL + SUPER + BRACKETLEFT", hl.dsp.focus({ workspace = "-1" }))
hl.bind("CTRL + SUPER + BRACKETRIGHT", hl.dsp.focus({ workspace = "+1" }))

hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session")) -- Lock
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("sleep 0.1 && systemctl suspend || loginctl suspend"), { locked = true }) -- Suspend system
hl.bind("CTRL + SHIFT + ALT + SUPER + DELETE", hl.dsp.exec_cmd("systemctl poweroff || loginctl poweroff")) -- Shutdown
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd(player_next), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(player_next), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("SUPER + SHIFT + ALT + mouse:275", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("SUPER + SHIFT + ALT + mouse:276", hl.dsp.exec_cmd(player_next))
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(
	"SUPER + T",
	hl.dsp.exec_cmd(
		launch_first_available
			.. ' "$TERMINAL" "kitty -1" "foot" "alacritty" "wezterm" "konsole" "kgx" "uxterm" "xterm"'
	)
)
hl.bind(
	"CTRL + ALT + T",
	hl.dsp.exec_cmd(
		launch_first_available
			.. ' "$TERMINAL" "kitty -1" "foot" "alacritty" "wezterm" "konsole" "kgx" "uxterm" "xterm"'
	)
)
hl.bind(
	"SUPER + E",
	hl.dsp.exec_cmd(
		launch_first_available .. ' "dolphin" "nautilus" "nemo" "thunar" "$TERMINAL" "kitty -1 fish -c yazi"'
	)
)
hl.bind(
	"SUPER + W",
	hl.dsp.exec_cmd(
		launch_first_available
			.. ' "google-chrome-stable" "brave" "zen-browser" "firefox" "chromium" "microsoft-edge-stable" "opera" "librewolf"'
	)
)
hl.bind(
	"SUPER + C",
	hl.dsp.exec_cmd(
		launch_first_available
			.. ' "code" "codium" "cursor" "zed" "zedit" "zeditor" "kate" "gnome-text-editor" "emacs" "command -v nvim && kitty -1 nvim"'
	)
)
hl.bind("SUPER + X", hl.dsp.exec_cmd(launch_first_available .. ' "kate" "gnome-text-editor" "emacs"'))
hl.bind("CTRL + SUPER + V", hl.dsp.exec_cmd(launch_first_available .. ' "pavucontrol" "pavucontrol"'))
hl.bind(
	"SUPER + I",
	hl.dsp.exec_cmd(
		"XDG_CURRENT_DESKTOP=gnome "
			.. launch_first_available
			.. ' "systemsettings" "gnome-control-center" "better-control"'
	)
)
hl.bind(
	"CTRL + SHIFT + ESCAPE",
	hl.dsp.exec_cmd(
		launch_first_available
			.. ' "gnome-system-monitor" "plasma-systemmonitor --page-name Processes" "command -v btop && kitty -1 fish -c btop"'
	)
)

-- TODO: create cheatsheet window with a list of keybinding; add comments in this file that will be used for descriptions in the cheatsheet
