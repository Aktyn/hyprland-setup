use gpui::{
    App, Bounds, DisplayId, Entity, Size, WindowBackgroundAppearance, WindowBounds, WindowKind,
    WindowOptions, layer_shell::*, point, px, size,
};

use crate::config::ConfigStore;
use crate::model::PanelKind;

pub(crate) fn bar_window_options(
    cx: &App,
    config: &Entity<ConfigStore>,
    display_id: Option<DisplayId>,
) -> WindowOptions {
    let displays = cx.displays();
    let display = displays
        .iter()
        .find(|display| Some(display.id()) == display_id);
    let width = display
        .map(|display| display.bounds().size.width)
        .unwrap_or(px(1920.));
    let height = px(config.read(cx).value.bar.height as f32);
    WindowOptions {
        display_id,
        titlebar: None,
        window_bounds: Some(WindowBounds::Windowed(Bounds {
            origin: point(px(0.), px(0.)),
            size: Size::new(width, height),
        })),
        app_id: Some("aktyn-shell".into()),
        window_background: WindowBackgroundAppearance::Transparent,
        kind: WindowKind::LayerShell(LayerShellOptions {
            namespace: "aktyn-shell-bar".into(),
            layer: Layer::Top,
            anchor: Anchor::TOP | Anchor::LEFT | Anchor::RIGHT,
            exclusive_zone: Some(height),
            margin: Some((px(0.), px(0.), px(0.), px(0.))),
            keyboard_interactivity: KeyboardInteractivity::None,
            ..Default::default()
        }),
        ..Default::default()
    }
}

pub(crate) fn panel_window_options(
    cx: &App,
    config: &Entity<ConfigStore>,
    display_id: Option<DisplayId>,
    panel_kind: PanelKind,
) -> WindowOptions {
    let display = cx
        .displays()
        .into_iter()
        .find(|display| Some(display.id()) == display_id);
    let overview = panel_kind == PanelKind::Overview;
    let width = if overview { px(820.) } else { px(500.) };
    let screen_size = display
        .as_ref()
        .map(|display| display.bounds().size)
        .unwrap_or(size(px(1920.), px(1080.)));
    let screen_width = f32::from(screen_size.width);
    let screen_height = f32::from(screen_size.height);
    let panel_width = f32::from(width);
    let height = if overview {
        px((screen_height - config.read(cx).value.bar.height as f32 - 32.).clamp(480., 840.))
    } else {
        px(720.)
    };
    let centered_margin = px(((screen_width - panel_width) / 2.).max(0.));
    let margin = if overview {
        (
            px(config.read(cx).value.bar.height as f32),
            centered_margin,
            px(0.),
            centered_margin,
        )
    } else {
        (
            px(config.read(cx).value.bar.height as f32 + 8.),
            px(16.),
            px(0.),
            px(0.),
        )
    };
    WindowOptions {
        display_id,
        titlebar: None,
        window_bounds: Some(WindowBounds::Windowed(Bounds {
            origin: point(px(0.), px(0.)),
            size: Size::new(width, height),
        })),
        app_id: Some("aktyn-shell-panel".into()),
        window_background: WindowBackgroundAppearance::Transparent,
        kind: WindowKind::LayerShell(LayerShellOptions {
            namespace: "aktyn-shell-panel".into(),
            layer: Layer::Top,
            anchor: if overview {
                Anchor::TOP | Anchor::LEFT | Anchor::RIGHT
            } else {
                Anchor::TOP | Anchor::RIGHT
            },
            margin: Some(margin),
            keyboard_interactivity: KeyboardInteractivity::OnDemand,
            ..Default::default()
        }),
        ..Default::default()
    }
}

pub(crate) fn tray_menu_window_options(
    cx: &App,
    config: &Entity<ConfigStore>,
    display_id: Option<DisplayId>,
) -> WindowOptions {
    WindowOptions {
        display_id,
        titlebar: None,
        window_bounds: Some(WindowBounds::Windowed(Bounds {
            origin: point(px(0.), px(0.)),
            size: size(px(280.), px(420.)),
        })),
        app_id: Some("aktyn-shell-tray-menu".into()),
        window_background: WindowBackgroundAppearance::Transparent,
        kind: WindowKind::LayerShell(LayerShellOptions {
            namespace: "aktyn-shell-tray-menu".into(),
            layer: Layer::Top,
            anchor: Anchor::TOP | Anchor::RIGHT,
            margin: Some((
                px(config.read(cx).value.bar.height as f32 + 8.),
                px(16.),
                px(0.),
                px(0.),
            )),
            keyboard_interactivity: KeyboardInteractivity::None,
            ..Default::default()
        }),
        ..Default::default()
    }
}

pub(crate) fn notification_toast_window_options(
    cx: &App,
    config: &Entity<ConfigStore>,
    display_id: Option<DisplayId>,
) -> WindowOptions {
    WindowOptions {
        display_id,
        titlebar: None,
        window_bounds: Some(WindowBounds::Windowed(Bounds {
            origin: point(px(0.), px(0.)),
            size: size(px(400.), px(520.)),
        })),
        app_id: Some("aktyn-shell-notifications".into()),
        window_background: WindowBackgroundAppearance::Transparent,
        kind: WindowKind::LayerShell(LayerShellOptions {
            namespace: "aktyn-shell-notifications".into(),
            layer: Layer::Overlay,
            anchor: Anchor::TOP | Anchor::RIGHT,
            margin: Some((
                px(config.read(cx).value.bar.height as f32 + 8.),
                px(16.),
                px(0.),
                px(0.),
            )),
            keyboard_interactivity: KeyboardInteractivity::None,
            ..Default::default()
        }),
        ..Default::default()
    }
}
