use std::path::PathBuf;

use gpui::{
    App, Context, Entity, ObjectFit, Render, Window, WindowBackgroundAppearance, WindowOptions,
    img, prelude::*,
};

use crate::config::ConfigStore;

pub(crate) struct ShellWallpaper {
    config: Entity<ConfigStore>,
}

impl ShellWallpaper {
    pub(crate) fn new(config: Entity<ConfigStore>, cx: &mut Context<Self>) -> Self {
        cx.observe(&config, |_, _, cx| cx.notify()).detach();
        Self { config }
    }
}

impl Render for ShellWallpaper {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let path = self.config.read(cx).value.wallpaper.path.clone();
        let mut wallpaper = gpui::div().size_full();
        if !path.is_empty() {
            wallpaper = wallpaper.child(
                img(PathBuf::from(path))
                    .size_full()
                    .object_fit(ObjectFit::Cover),
            );
        }
        wallpaper
    }
}

pub(crate) fn wallpaper_window_options(
    _cx: &App,
    display_id: Option<gpui::DisplayId>,
) -> WindowOptions {
    WindowOptions {
        display_id,
        titlebar: None,
        app_id: Some("aktyn-shell-wallpaper".into()),
        window_background: WindowBackgroundAppearance::Transparent,
        kind: gpui::WindowKind::LayerShell(gpui::layer_shell::LayerShellOptions {
            namespace: "aktyn-shell-wallpaper".into(),
            layer: gpui::layer_shell::Layer::Background,
            anchor: gpui::layer_shell::Anchor::TOP
                | gpui::layer_shell::Anchor::BOTTOM
                | gpui::layer_shell::Anchor::LEFT
                | gpui::layer_shell::Anchor::RIGHT,
            keyboard_interactivity: gpui::layer_shell::KeyboardInteractivity::None,
            ..Default::default()
        }),
        ..Default::default()
    }
}
