-- hl.monitor({ output="", name = "", res = "preferred", offset = "auto", scale = "auto" })
hl.monitor({ output="", scale = "auto" })

-- Define Bézier curves
hl.curve("emphasizedDecel", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("emphasizedAccel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("menu_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("menu_accel", { type = "bezier", points = { { 0.52, 0.03 }, { 0.72, 0.08 } } })

-- Define Animations
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "emphasizedDecel", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "emphasizedDecel", style = "popin 90%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "emphasizedDecel", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "emphasizedDecel" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.7, bezier = "emphasizedDecel", style = "popin 93%" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.4, bezier = "menu_accel", style = "popin 94%" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 0.5, bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2.7, bezier = "menu_accel" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 7, bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 2.8, bezier = "emphasizedDecel", style = "slidevert" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 1.2, bezier = "emphasizedAccel", style = "slidevert" })

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 5,
        gaps_workspaces = 64,
        border_size = 1,
        ['col.active_border'] = "rgb(90A4AE)",
        ['col.inactive_border'] = "rgb(37474F)",
        resize_on_border = true,
        hover_icon_on_border = false,
        resize_corner = 0,
        extend_border_grab_area = 16,
        no_focus_fallback = true,
        allow_tearing = true,
        layout = "dwindle",
        snap = {
            enabled = true
        }
    },

    dwindle = {
        preserve_split = true,
        smart_split = true,
        smart_resizing = true,
        split_width_multiplier = 1.777,
        default_split_ratio = 1.23607,
        split_bias = 1
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
            xray = false,
            special = false
        },
        shadow = {
            enabled = true,
            range = 24,
            offset = "0 2",
            render_power = 3,
            color = "rgba(00000040)"
        }
    },

    animations = {
        enabled = true,
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
            scroll_factor = 0.5
        }
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
        background_color = "rgb(263238)"
    },

    cursor = {
        zoom_factor = 1,
        zoom_rigid = false,
        no_hardware_cursors = 2,
        no_warps = true
    },

    xwayland = {
        enabled = true,
        force_zero_scaling = true
    },

    render = {
        direct_scanout = 1,
        cm_auto_hdr = 2
    },

    gestures = {
        workspace_swipe_distance = 700,
        workspace_swipe_cancel_ratio = 0.2,
        workspace_swipe_min_speed_to_force = 5,
        workspace_swipe_direction_lock = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new = true
    },

    ecosystem = {
        no_donation_nag = true
    }
})

-- Legacy singular gesture (if still needed, otherwise it's likely handled by gestures block)
-- gesture = 3, horizontal, workspace
-- In Lua, this might be:
-- hl.gesture({ fingers = 3, direction = "horizontal", dispatcher = "workspace" })
-- But usually it's better to stick to the gestures block if possible.
-- For now, I'll omit it as the gestures block covers swipe.
