hl.config({
	general = {
		gaps_in = 4,
		gaps_out = 5,
		gaps_workspaces = 64,

		border_size = 1,
		col = {
			active_border = "rgb(90A4AE)",
			inactive_border = "rgb(37474F)",
		},
		resize_on_border = true,
		hover_icon_on_border = false,
		resize_corner = 0,
		extend_border_grab_area = 16,

		no_focus_fallback = true,
		allow_tearing = true, -- Allows the `immediate` window rule to work

		layout = "dwindle",

		snap = {
			enabled = true,
		},
	},

	dwindle = {
		preserve_split = true,
		smart_split = true,
		smart_resizing = true,
		split_width_multiplier = 1.777, -- Should equal screen width / height ratio; override in custom.conf
		default_split_ratio = 1.23607, -- Used golden ratio for splitting (2 / 1.61803398875 = 1.23607)
		split_bias = 1,
	},

	decoration = {
		rounding = 16,

		dim_inactive = false,

		blur = {
			size = 8,
			passes = 3,
			noise = 0.02,
			brightness = 1,
			contrast = 1,
			vibrancy = 0.5,

			popups = true,
			popups_ignorealpha = 0.2,

			input_methods = true,
			input_methods_ignorealpha = 0.2,

			new_optimizations = true,
			xray = false, -- If true, ignores what is behind floating windows
			special = false,
		},

		shadow = {
			enabled = true,
			-- ignore_window = true
			range = 24,
			offset = "0 2",
			render_power = 3,
			color = "rgba(00000040)",
		},
	},

	input = {
		kb_layout = "us",
		numlock_by_default = true,
		repeat_delay = 250,
		repeat_rate = 35,

		follow_mouse = 1,
		mouse_refocus = false,
		off_window_axis_events = 2,

		touchpad = {
			natural_scroll = true,
			disable_while_typing = true,
			clickfinger_behavior = true,
			scroll_factor = 0.5,
		},
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		vrr = true,
		mouse_move_enables_dpms = true,
		key_press_enables_dpms = true,
		animate_manual_resizes = false,
		animate_mouse_windowdragging = false,
		enable_swallow = false,
		on_focus_under_fullscreen = 1,
		allow_session_lock_restore = true,
		session_lock_xray = true,
		initial_workspace_tracking = false,
		focus_on_activate = true,
		force_default_wallpaper = 0,
		background_color = "rgb(263238)",
	},

	cursor = {
		zoom_factor = 1,
		zoom_rigid = false,
		no_hardware_cursors = 2, -- 2 - auto (disable when tearing)
		no_warps = true,
	},

	xwayland = {
		enabled = true,
		force_zero_scaling = true,
	},

	render = {
		direct_scanout = 1,
		cm_auto_hdr = 2,
	},

	-- See https://wiki.hypr.land/Configuring/Gestures
	gestures = {
		workspace_swipe_distance = 700,
		workspace_swipe_cancel_ratio = 0.2,
		workspace_swipe_min_speed_to_force = 5,
		workspace_swipe_direction_lock = true,
		workspace_swipe_direction_lock_threshold = 10,
		workspace_swipe_create_new = true,
	},

	ecosystem = {
		no_donation_nag = true,
	},
})

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Bezier curves
hl.curve("md3_decel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("md3_accel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("menu_accel", { type = "bezier", points = { { 0.38, 0.04 }, { 1, 0.07 } } })
-- 0.65, 0, 0.35, 1
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0 }, { 0.35, 1 } } })

-- Spring Curves
hl.curve("spring_menu", { type = "spring", mass = 1, stiffness = 80, dampening = 14 })
hl.curve("spring_window", { type = "spring", mass = 1, stiffness = 30, dampening = 8 })
hl.curve("spring_open", { type = "spring", mass = 1, stiffness = 30, dampening = 8 })
hl.curve("spring_workspace", { type = "spring", mass = 1.2, stiffness = 30, dampening = 10 })
hl.curve("spring_special", { type = "spring", mass = 1, stiffness = 30, dampening = 8 })

-- Window animations
hl.animation({ leaf = "windows", enabled = true, speed = 1, spring = "spring_window" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, spring = "spring_open", style = "popin 40%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "md3_accel", style = "popin 60%" })

-- Border animations (disabled)
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "easeInOutCubic" })
hl.animation({ leaf = "borderangle", enabled = false })

-- Fade
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "md3_decel" })

-- Zoom cursor
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 6, bezier = "md3_decel" })

-- Layer animations
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, spring = "spring_menu", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.6, bezier = "menu_accel", style = "slide" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2, bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.6, bezier = "menu_accel" })

-- Workspace animations
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, spring = "spring_workspace", style = "slide" })
hl.animation({
	leaf = "specialWorkspace",
	enabled = true,
	speed = 1,
	spring = "spring_special",
	style = "slidefadevert 40%",
})
