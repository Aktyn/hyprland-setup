local scripts_dir = os.getenv("HOME") .. "/.config/hypr/scripts/"
local workspace_action = scripts_dir .. "workspace_action.sh"
local launch_first_available = scripts_dir .. "launch_first_available.sh"
local player_next =
	'playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"`'

local toggleLeftMenuDescription = "Toggle left menu"
local toggleCheetsheetPanelDescription = "Toogle cheetsheet panel"
local interruptOverviewDescription = "Interrupt overview toggle"
local toggleMuteDescription = "Toggle mute"
local toggleMicMuteDescription = "Toggle mic mute"
local dragWindowDescription = "Drag window"
local focusLeftDescription = "Focus left"
local focusRightDescription = "Focus right"
local moveWindowLeftDescription = "Move window left"
local moveWindowRightDescription = "Move window right"
local toggleFloatingDescription = "Toggle floating"
local moveNextRelWorkspaceDescription = "Move window to next relative workspace"
local movePrevRelWorkspaceDescription = "Move window to previous relative workspace"
local moveNextWorkspaceDescription = "Move window to next workspace"
local movePrevWorkspaceDescription = "Move window to previous workspace"
local focusNextRelWorkspaceDescription = "Focus next relative workspace"
local focusPrevRelWorkspaceDescription = "Focus previous relative workspace"
local focusNextWorkspaceDescription = "Focus next workspace"
local focusPrevWorkspaceDescription = "Focus previous workspace"
local lockSessionDescription = "Lock session"
local nextTrackDescription = "Next track"
local prevTrackDescription = "Previous track"
local playPauseDescription = "Play/Pause"
local launchTerminalDescription = "Launch Terminal"

hl.bind(
	"SUPER + SUPER_L",
	hl.dsp.global("quickshell:overviewToggleRelease"),
	{ release = true, description = toggleLeftMenuDescription }
)
hl.bind(
	"SUPER + SUPER_R",
	hl.dsp.global("quickshell:overviewToggleRelease"),
	{ release = true, description = toggleLeftMenuDescription }
)

hl.bind(
	"SUPER + SLASH",
	hl.dsp.global("quickshell:osdCheetsheetToggle"),
		{ description = toggleCheetsheetPanelDescription }
)
hl.bind(
	"SUPER + BACKSLASH",
	hl.dsp.global("quickshell:osdCheetsheetToggle"),
		{ description = toggleCheetsheetPanelDescription }
)

hl.bind("CTRL + SUPER_L", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), {
	description = interruptOverviewDescription,
})
hl.bind("CTRL + SUPER_R", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), {
	description = interruptOverviewDescription,
})
hl.bind("SUPER + mouse:272", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), {
	mouse = true,
	description = interruptOverviewDescription,
})
hl.bind("SUPER + mouse:273", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), {
	mouse = true,
	description = interruptOverviewDescription,
})
hl.bind("SUPER + mouse:274", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), {
	mouse = true,
	description = interruptOverviewDescription,
})
hl.bind("SUPER + mouse:275", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), {
	mouse = true,
	description = interruptOverviewDescription,
})
hl.bind("SUPER + mouse:276", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), {
	mouse = true,
	description = interruptOverviewDescription,
})
hl.bind("SUPER + mouse:277", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), {
	mouse = true,
	description = interruptOverviewDescription,
})
hl.bind("SUPER + mouse_up", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), {
	description = interruptOverviewDescription,
})
hl.bind("SUPER + mouse_down", hl.dsp.global("quickshell:overviewToggleReleaseInterrupt"), {
	description = interruptOverviewDescription,
})

hl.bind("SUPER + V", hl.dsp.global("quickshell:overviewClipboardToggle"), {
	description = "Toggle clipboard history",
})

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 2%+"),
	{ locked = true, ["repeat"] = true, description = "Raise volume" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),
	{ locked = true, ["repeat"] = true, description = "Lower volume" }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), {
	locked = true,
	description = toggleMuteDescription,
})
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle"), {
	locked = true,
	description = toggleMuteDescription,
})
hl.bind("ALT + XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), {
	locked = true,
	description = toggleMicMuteDescription,
})
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), {
	locked = true,
	description = toggleMicMuteDescription,
})
hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), {
	locked = true,
	description = toggleMicMuteDescription,
})

hl.bind("CTRL + SUPER + R", hl.dsp.exec_cmd("killall ags agsv1 gjs qs quickshell; qs -c aktyn &"), {
	description = "Reload shell",
})
hl.bind(
	"SUPER + SHIFT + S",
	hl.dsp.exec_cmd("pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent"),
	{ description = "Screen snip" }
)
hl.bind(
	"SUPER + SHIFT + T",
	hl.dsp.exec_cmd(
		'grim -g "$(slurp $SLURP_ARGS)" "tmp.png" && tesseract "tmp.png" - | wl-copy && rm "tmp.png"'
	),
	{ description = "OCR (Character recognition)" }
)
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), { description = "Color picker" })
hl.bind(
	"PRINT",
	hl.dsp.exec_cmd("grim -c -o \"$(hyprctl activeworkspace -j | jq -r '.monitor')\" - | wl-copy"),
	{ locked = true, description = "Screenshot to clipboard" }
)

-- Mouse window management
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = dragWindowDescription })
hl.bind("SUPER + mouse:274", hl.dsp.window.drag(), { mouse = true, description = dragWindowDescription })
hl.bind(
	"SUPER + mouse:273",
	hl.dsp.window.resize(),
	{ mouse = true, description = "Resize window" }
)

-- Focus movement
hl.bind("SUPER + Left", hl.dsp.focus({ direction = "l" }), { description = focusLeftDescription })
hl.bind("SUPER + Right", hl.dsp.focus({ direction = "r" }), { description = focusRightDescription })
hl.bind("SUPER + Up", hl.dsp.focus({ direction = "u" }), { description = "Focus up" })
hl.bind("SUPER + Down", hl.dsp.focus({ direction = "d" }), { description = "Focus down" })
hl.bind(
	"SUPER + BracketLeft",
	hl.dsp.focus({ direction = "l" }),
	{ description = focusLeftDescription }
)
hl.bind(
	"SUPER + BracketRight",
	hl.dsp.focus({ direction = "r" }),
	{ description = focusRightDescription }
)

-- Window movement
hl.bind("SUPER + SHIFT + Left", hl.dsp.window.move({ direction = "l" }), {
	description = moveWindowLeftDescription,
})
hl.bind("SUPER + SHIFT + Right", hl.dsp.window.move({ direction = "r" }), {
	description = moveWindowRightDescription,
})
hl.bind("SUPER + SHIFT + Up", hl.dsp.window.move({ direction = "u" }), {
	description = "Move window up",
})
hl.bind("SUPER + SHIFT + Down", hl.dsp.window.move({ direction = "d" }), {
	description = "Move window down",
})

-- Window control
hl.bind("ALT + F4", hl.dsp.window.kill(), { description = "Kill window" })
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Close window" })
hl.bind("SUPER + SHIFT + ALT + Q", hl.dsp.exec_cmd("hyprctl kill"), {
	description = "Force kill window (hyprctl kill)",
})

hl.bind("SUPER + SEMICOLON", hl.dsp.layout("splitratio -0.1"), {
	description = "Decrease split ratio",
})
hl.bind("SUPER + APOSTROPHE", hl.dsp.layout("splitratio +0.1"), {
	description = "Increase split ratio",
})
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"), { description = "Toggle split orientation" })

hl.bind("SUPER + ALT + SPACE", hl.dsp.window.float({ action = "toggle" }), {
	description = toggleFloatingDescription,
})
hl.bind("SUPER + SPACE", hl.dsp.window.float({ action = "toggle" }), {
	description = toggleFloatingDescription,
})
hl.bind("SUPER + D", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), {
	description = "Maximize window",
})
hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), {
	description = "Fullscreen window",
})
hl.bind(
	"SUPER + ALT + F",
	hl.dsp.window.fullscreen_state({ internal = 3, client = 0, action = "toggle" }),
	{ description = "Fullscreen (internal state)" }
)
hl.bind("SUPER + P", hl.dsp.window.pin(), { description = "Pin window" })

for i = 1, 10 do
	local key = i % 10
	hl.bind(
		"SUPER + ALT + " .. key,
		hl.dsp.exec_cmd(workspace_action .. " movetoworkspacesilent " .. i),
		{ description = "Move window to workspace " .. i .. " (silent)" }
	)
	hl.bind("SUPER + " .. key, hl.dsp.exec_cmd(workspace_action .. " workspace " .. i), {
		description = "Switch to workspace " .. i,
	})
end

hl.bind("SUPER + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "r-1" }), {
	description = movePrevRelWorkspaceDescription,
})
hl.bind("SUPER + SHIFT + mouse_up", hl.dsp.window.move({ workspace = "r+1" }), {
	description = moveNextRelWorkspaceDescription,
})
hl.bind("SUPER + ALT + mouse_down", hl.dsp.window.move({ workspace = "-1" }), {
	description = movePrevWorkspaceDescription,
})
hl.bind("SUPER + ALT + mouse_up", hl.dsp.window.move({ workspace = "+1" }), {
	description = moveNextWorkspaceDescription,
})
hl.bind("SUPER + ALT + Page_Down", hl.dsp.window.move({ workspace = "+1" }), {
	description = moveNextWorkspaceDescription,
})
hl.bind("SUPER + ALT + Page_Up", hl.dsp.window.move({ workspace = "-1" }), {
	description = movePrevWorkspaceDescription,
})
hl.bind("SUPER + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "r+1" }), {
	description = moveNextRelWorkspaceDescription,
})
hl.bind("SUPER + SHIFT + Page_Up", hl.dsp.window.move({ workspace = "r-1" }), {
	description = movePrevRelWorkspaceDescription,
})
hl.bind("CTRL + SUPER + SHIFT + RIGHT", hl.dsp.window.move({ workspace = "r+1" }), {
	description = moveNextRelWorkspaceDescription,
})
hl.bind("CTRL + SUPER + SHIFT + LEFT", hl.dsp.window.move({ workspace = "r-1" }), {
	description = movePrevRelWorkspaceDescription,
})

hl.bind("ALT + Tab", function()
	hl.dispatch(hl.dsp.window.cycle_next())
	hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "Cycle next window" })
hl.bind("ALT + SHIFT + Tab", function()
	hl.dispatch(hl.dsp.window.cycle_next(-1))
	hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "Cycle previous window" })

hl.bind("CTRL + SUPER + RIGHT", hl.dsp.focus({ workspace = "r+1" }), {
	description = focusNextRelWorkspaceDescription,
})
hl.bind("CTRL + SUPER + LEFT", hl.dsp.focus({ workspace = "r-1" }), {
	description = focusPrevRelWorkspaceDescription,
})
hl.bind("CTRL + SUPER + ALT + RIGHT", hl.dsp.focus({ workspace = "m+1" }), {
	description = "Focus next monitor workspace",
})
hl.bind("CTRL + SUPER + ALT + LEFT", hl.dsp.focus({ workspace = "m-1" }), {
	description = "Focus previous monitor workspace",
})
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "+1" }), {
	description = focusNextWorkspaceDescription,
})
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "-1" }), {
	description = focusPrevWorkspaceDescription,
})
hl.bind("CTRL + SUPER + Page_Down", hl.dsp.focus({ workspace = "r+1" }), {
	description = focusNextRelWorkspaceDescription,
})
hl.bind("CTRL + SUPER + Page_Up", hl.dsp.focus({ workspace = "r-1" }), {
	description = focusPrevRelWorkspaceDescription,
})
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "+1" }), {
	description = focusNextWorkspaceDescription,
})
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "-1" }), {
	description = focusPrevWorkspaceDescription,
})
hl.bind("CTRL + SUPER + mouse_up", hl.dsp.focus({ workspace = "r+1" }), {
	description = focusNextRelWorkspaceDescription,
})
hl.bind("CTRL + SUPER + mouse_down", hl.dsp.focus({ workspace = "r-1" }), {
	description = focusPrevRelWorkspaceDescription,
})
hl.bind("CTRL + SUPER + BRACKETLEFT", hl.dsp.focus({ workspace = "-1" }), {
	description = focusPrevWorkspaceDescription,
})
hl.bind("CTRL + SUPER + BRACKETRIGHT", hl.dsp.focus({ workspace = "+1" }), {
	description = focusNextWorkspaceDescription,
})

hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = lockSessionDescription })
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("loginctl lock-session"), {
	description = lockSessionDescription,
})
hl.bind(
	"SUPER + SHIFT + L",
	hl.dsp.exec_cmd("sleep 0.1 && systemctl suspend || loginctl suspend"),
	{ locked = true, description = "Suspend system" }
)
hl.bind(
	"CTRL + SHIFT + ALT + SUPER + DELETE",
	hl.dsp.exec_cmd("systemctl poweroff || loginctl poweroff"),
	{ description = "Shutdown system" }
)
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd(player_next), {
	locked = true,
	description = nextTrackDescription,
})
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(player_next), {
	locked = true,
	description = nextTrackDescription,
})
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), {
	locked = true,
	description = prevTrackDescription,
})
hl.bind("SUPER + SHIFT + ALT + mouse:275", hl.dsp.exec_cmd("playerctl previous"), {
	description = prevTrackDescription,
})
hl.bind("SUPER + SHIFT + ALT + mouse:276", hl.dsp.exec_cmd(player_next), {
	description = nextTrackDescription,
})
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd("playerctl previous"), {
	locked = true,
	description = prevTrackDescription,
})
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("playerctl play-pause"), {
	locked = true,
	description = playPauseDescription,
})
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), {
	locked = true,
	description = playPauseDescription,
})
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), {
	locked = true,
	description = playPauseDescription,
})
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"), { description = "Launch Terminal (kitty)" })
hl.bind(
	"SUPER + T",
	hl.dsp.exec_cmd(
		launch_first_available
			.. ' "$TERMINAL" "kitty -1" "foot" "alacritty" "wezterm" "konsole" "kgx" "uxterm" "xterm"'
	),
	{ description = launchTerminalDescription }
)
hl.bind(
	"CTRL + ALT + T",
	hl.dsp.exec_cmd(
		launch_first_available
			.. ' "$TERMINAL" "kitty -1" "foot" "alacritty" "wezterm" "konsole" "kgx" "uxterm" "xterm"'
	),
	{ description = launchTerminalDescription }
)
hl.bind(
	"SUPER + E",
	hl.dsp.exec_cmd(
		launch_first_available
			.. ' "dolphin" "nautilus" "nemo" "thunar" "$TERMINAL" "kitty -1 fish -c yazi"'
	),
	{ description = "Launch File Manager" }
)
hl.bind(
	"SUPER + W",
	hl.dsp.exec_cmd(
		launch_first_available
			.. ' "$BROWSER" "google-chrome-stable" "brave" "zen-browser" "firefox" "chromium" "microsoft-edge-stable" "opera" "librewolf"'
	),
	{ description = "Launch Browser" }
)
hl.bind(
	"SUPER + C",
	hl.dsp.exec_cmd(
		launch_first_available
			.. ' "code" "codium" "cursor" "zed" "zedit" "zeditor" "kate" "gnome-text-editor" "emacs" "command -v nvim && kitty -1 nvim"'
	),
	{ description = "Launch Code Editor" }
)
hl.bind(
	"SUPER + X",
	hl.dsp.exec_cmd(launch_first_available .. ' "kate" "gnome-text-editor" "emacs"'),
	{ description = "Launch Text Editor" }
)
hl.bind(
	"CTRL + SUPER + V",
	hl.dsp.exec_cmd(launch_first_available .. ' "pavucontrol" "pavucontrol"'),
	{ description = "Launch Audio Control" }
)
hl.bind(
	"SUPER + I",
	hl.dsp.exec_cmd(
		"XDG_CURRENT_DESKTOP=gnome "
			.. launch_first_available
			.. ' "systemsettings" "gnome-control-center" "better-control"'
	),
	{ description = "Launch Settings" }
)
hl.bind(
	"CTRL + SHIFT + ESCAPE",
	hl.dsp.exec_cmd(
		launch_first_available
			.. ' "gnome-system-monitor" "plasma-systemmonitor --page-name Processes" "command -v btop && kitty -1 fish -c btop"'
	),
	{ description = "Launch System Monitor" }
)