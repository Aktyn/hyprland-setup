-- Keybinds Configuration for Hyprland 0.55+ (Lua Syntax)

hl.define_submap("global", function()
	-- Overview toggles
	hl.bind(
		"SUPER + SUPER_L",
		hl.dsp.global("quickshell:overviewToggleRelease"),
		{ ignore_mods = true, description = "Toggle overview" }
	)
	hl.bind(
		"SUPER + SUPER_R",
		hl.dsp.global("quickshell:overviewToggleRelease"),
		{ ignore_mods = true, description = "Toggle overview" }
	)

	-- Catchall / Interrupt binds
	hl.bind(
		"catchall",
		hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"),
		{ ignore_mods = true, transparent = true, non_consuming = true }
	)
	hl.bind("CTRL + SUPER_L", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"))
	hl.bind("CTRL + SUPER_R", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"))
	hl.bind("SUPER + mouse:272", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"))
	hl.bind("SUPER + mouse:273", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"))
	hl.bind("SUPER + mouse:274", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"))
	hl.bind("SUPER + mouse:275", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"))
	hl.bind("SUPER + mouse:276", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"))
	hl.bind("SUPER + mouse:277", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"))
	hl.bind("SUPER + mouse_up", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"))
	hl.bind("SUPER + mouse_down", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"))

	-- Clipboard
	hl.bind(
		"SUPER + V",
		hl.dsp.global("quickshell:overviewClipboardToggle"),
		{ description = "Clipboard history >> clipboard" }
	)

	-- Volume controls
	hl.bind(
		"XF86AudioRaiseVolume",
		hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+"),
		{ locked = true, repeating = true }
	)
	hl.bind(
		"XF86AudioLowerVolume",
		hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),
		{ locked = true, repeating = true }
	)
	hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), { locked = true })
	hl.bind(
		"SUPER + SHIFT + M",
		hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"),
		{ locked = true, description = "Toggle mute" }
	)
	hl.bind("ALT + XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
	hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })
	hl.bind(
		"SUPER + ALT + M",
		hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"),
		{ locked = true, description = "Toggle mic" }
	)

	-- System utilities
	hl.bind("CTRL + SUPER + R", hl.dsp.exec_cmd("killall ags agsv1 gjs qs quickshell; qs -c aktyn &"))
	hl.bind(
		"SUPER + SHIFT + S",
		hl.dsp.exec_cmd("pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent"),
		{ description = "Screen snip" }
	)
	hl.bind(
		"SUPER + SHIFT + T",
		hl.dsp.exec_cmd('grim -g "$(slurp $SLURP_ARGS)" "tmp.png" && tesseract "tmp.png" - | wl-copy && rm "tmp.png"'),
		{ description = "Character recognition" }
	)
	hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Color picker" })
	hl.bind(
		"Print",
		hl.dsp.exec_cmd("grim -c -o \"$(hyprctl activeworkspace -j | jq -r '.monitor')\" - | wl-copy"),
		{ locked = true, description = "Screenshot >> clipboard" }
	)

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

	-- Layout & Floating
	hl.bind("SUPER + Semicolon", hl.dsp.layout("splitratio -0.1"), { repeating = true })
	hl.bind("SUPER + Apostrophe", hl.dsp.layout("splitratio +0.1"), { repeating = true })
	hl.bind("SUPER + J", hl.dsp.layout("togglesplit"))
	hl.bind("SUPER + ALT + Space", hl.dsp.window.float({ action = "toggle" }))
	hl.bind("SUPER + Space", hl.dsp.window.float({ action = "toggle" }))
	hl.bind("SUPER + D", hl.dsp.window.fullscreen({ mode = 1 }))
	hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = 0 }))
	hl.bind("SUPER + ALT + F", hl.dsp.window.fullscreen_state({ internal = 0, client = 3 }))
	hl.bind("SUPER + P", hl.dsp.window.pin())

	-- Workspaces
	local function workspace_action(action, key)
		local active = hl.get_active_workspace()
		if not active then
			return
		end

		local active_id = active.id
		local group = 0
		if active_id > 0 then
			group = math.floor((active_id - 1) / 10)
		end

		local target = tostring(group * 10 + key)

		if action == "focus" then
			hl.dispatch(hl.dsp.focus({ workspace = target }))
		elseif action == "move" then
			hl.dispatch(hl.dsp.window.move({ workspace = target, follow = false }))
		end
	end

	for i = 1, 10 do
		local key = tostring(i % 10)
		hl.bind("SUPER + " .. key, function()
			workspace_action("focus", i)
		end, { description = "Switch to workspace " .. (i % 10) })
		hl.bind("SUPER + ALT + " .. key, function()
			workspace_action("move", i)
		end, { description = "Move window to workspace " .. (i % 10) })
	end

	hl.bind("SUPER + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "r-1", follow = true }))
	hl.bind("SUPER + SHIFT + mouse_up", hl.dsp.window.move({ workspace = "r+1", follow = true }))
	hl.bind("SUPER + ALT + mouse_down", hl.dsp.window.move({ workspace = "-1", follow = true }))
	hl.bind("SUPER + ALT + mouse_up", hl.dsp.window.move({ workspace = "+1", follow = true }))
	hl.bind("SUPER + ALT + Page_Down", hl.dsp.window.move({ workspace = "+1", follow = true }))
	hl.bind("SUPER + ALT + Page_Up", hl.dsp.window.move({ workspace = "-1", follow = true }))
	hl.bind("SUPER + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "r+1", follow = true }))
	hl.bind("SUPER + SHIFT + Page_Up", hl.dsp.window.move({ workspace = "r-1", follow = true }))
	hl.bind("CTRL + SUPER + SHIFT + Right", hl.dsp.window.move({ workspace = "r+1", follow = true }))
	hl.bind("CTRL + SUPER + SHIFT + Left", hl.dsp.window.move({ workspace = "r-1", follow = true }))

	-- Navigation
	hl.bind("ALT + Tab", function()
		hl.dispatch(hl.dsp.window.cycle_next())
		hl.dispatch(hl.dsp.window.bring_to_top())
	end)

	hl.bind("CTRL + SUPER + Right", hl.dsp.focus({ workspace = "r+1" }))
	hl.bind("CTRL + SUPER + Left", hl.dsp.focus({ workspace = "r-1" }))
	hl.bind("CTRL + SUPER + ALT + Right", hl.dsp.focus({ workspace = "m+1" }))
	hl.bind("CTRL + SUPER + ALT + Left", hl.dsp.focus({ workspace = "m-1" }))
	hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "+1" }))
	hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "-1" }))
	hl.bind("CTRL + SUPER + Page_Down", hl.dsp.focus({ workspace = "r+1" }))
	hl.bind("CTRL + SUPER + Page_Up", hl.dsp.focus({ workspace = "r-1" }))
	hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "+1" }))
	hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "-1" }))
	hl.bind("CTRL + SUPER + mouse_up", hl.dsp.focus({ workspace = "r+1" }))
	hl.bind("CTRL + SUPER + mouse_down", hl.dsp.focus({ workspace = "r-1" }))
	hl.bind("CTRL + SUPER + BracketLeft", hl.dsp.focus({ workspace = "-1" }))
	hl.bind("CTRL + SUPER + BracketRight", hl.dsp.focus({ workspace = "+1" }))

	-- Session control
	hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Lock" })
	hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("loginctl lock-session"))
	hl.bind(
		"SUPER + SHIFT + L",
		hl.dsp.exec_cmd("sleep 0.1 && systemctl suspend || loginctl suspend"),
		{ locked = true, description = "Suspend system" }
	)
	hl.bind(
		"CTRL + SHIFT + ALT + SUPER + Delete",
		hl.dsp.exec_cmd("systemctl poweroff || loginctl poweroff"),
		{ description = "Shutdown" }
	)

	-- Media player
	local next_player_cmd =
		'playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"`'
	hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd(next_player_cmd), { locked = true })
	hl.bind("XF86AudioNext", hl.dsp.exec_cmd(next_player_cmd), { locked = true })
	hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
	hl.bind("SUPER + SHIFT + ALT + mouse:275", hl.dsp.exec_cmd("playerctl previous"))
	hl.bind("SUPER + SHIFT + ALT + mouse:276", hl.dsp.exec_cmd(next_player_cmd))
	hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
	hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
	hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
	hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

	-- Terminals & Apps
	hl.bind("SUPER + Return", hl.dsp.exec_cmd("kitty"))

	local terminal_cmd =
		'~/.config/hypr/scripts/launch_first_available.sh "$TERMINAL" "kitty -1" "foot" "alacritty" "wezterm" "konsole" "kgx" "uxterm" "xterm"'
	hl.bind("SUPER + T", hl.dsp.exec_cmd(terminal_cmd))
	hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd(terminal_cmd))

	hl.bind(
		"SUPER + E",
		hl.dsp.exec_cmd(
			'~/.config/hypr/scripts/launch_first_available.sh "dolphin" "nautilus" "nemo" "thunar" "$TERMINAL" "kitty -1 fish -c yazi"'
		)
	)
	hl.bind(
		"SUPER + W",
		hl.dsp.exec_cmd(
			'~/.config/hypr/scripts/launch_first_available.sh "google-chrome-stable" "brave" "zen-browser" "firefox" "chromium" "microsoft-edge-stable" "opera" "librewolf"'
		)
	)
	hl.bind(
		"SUPER + C",
		hl.dsp.exec_cmd(
			'~/.config/hypr/scripts/launch_first_available.sh "code" "codium" "cursor" "zed" "zedit" "zeditor" "kate" "gnome-text-editor" "emacs" "command -v nvim && kitty -1 nvim"'
		)
	)
	hl.bind(
		"SUPER + X",
		hl.dsp.exec_cmd('~/.config/hypr/scripts/launch_first_available.sh "kate" "gnome-text-editor" "emacs"')
	)
	hl.bind(
		"CTRL + SUPER + V",
		hl.dsp.exec_cmd('~/.config/hypr/scripts/launch_first_available.sh "pavucontrol" "pavucontrol"')
	)
	hl.bind(
		"SUPER + I",
		hl.dsp.exec_cmd(
			'XDG_CURRENT_DESKTOP=gnome ~/.config/hypr/scripts/launch_first_available.sh "systemsettings" "gnome-control-center" "better-control"'
		)
	)
	hl.bind(
		"CTRL + SHIFT + Escape",
		hl.dsp.exec_cmd(
			'~/.config/hypr/scripts/launch_first_available.sh "gnome-system-monitor" "plasma-systemmonitor --page-name Processes" "command -v btop && kitty -1 fish -c btop"'
		)
	)
end)

hl.dispatch(hl.dsp.submap("global")) -- Enter global submap after registration
