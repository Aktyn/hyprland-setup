use gpui::{Context, Entity, MouseButton, Render, Window, div, prelude::*, px, rgb};

use crate::{
    services::{TrayItem, TrayMenuEntry, TrayService},
    ui::ShellBar,
};

use super::{
    bar_button,
    theme::{foreground, muted, outline, surface_high},
};

pub(crate) struct ShellTrayMenu {
    parent: Entity<ShellBar>,
    item: TrayItem,
    service: TrayService,
}

impl ShellTrayMenu {
    pub(crate) fn new(
        parent: Entity<ShellBar>,
        item: TrayItem,
        service: TrayService,
        _: &mut Context<Self>,
    ) -> Self {
        Self {
            parent,
            item,
            service,
        }
    }

    fn close(&mut self, cx: &mut Context<Self>) {
        self.parent.update(cx, |bar, cx| bar.close_tray_menu(cx));
    }

    fn activate(&mut self, id: i32, cx: &mut Context<Self>) {
        self.service
            .menu_item_clicked(self.item.name.clone(), self.item.menu_path.clone(), id);
        self.close(cx);
    }
}

impl Render for ShellTrayMenu {
    fn render(&mut self, _: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let mut entries = Vec::new();
        flatten_menu_entries(&self.item.menu, 0, &mut entries);
        let rows = entries.into_iter().map(|(id, label, enabled)| {
            let click = cx.listener(move |menu, _, _, cx| menu.activate(id, cx));
            let mut row = div()
                .w_full()
                .px(px(10.))
                .py(px(8.))
                .rounded(px(9.))
                .text_size(px(12.))
                .text_color(rgb(if enabled { foreground() } else { muted() }))
                .child(label);
            if enabled {
                row = row.on_mouse_down(MouseButton::Left, click);
            }
            row
        });
        div()
            .id("tray-menu")
            .size_full()
            .max_h(px(420.))
            .overflow_y_scroll()
            .p(px(8.))
            .flex()
            .flex_col()
            .gap(px(2.))
            .bg(rgb(surface_high()))
            .border_1()
            .border_color(rgb(outline()))
            .rounded(px(14.))
            .children(rows)
            .child(bar_button("Close", false).on_mouse_down(
                MouseButton::Left,
                cx.listener(|menu, _, _, cx| menu.close(cx)),
            ))
    }
}

fn flatten_menu_entries(
    items: &[TrayMenuEntry],
    depth: usize,
    output: &mut Vec<(i32, String, bool)>,
) {
    for item in items {
        if !item.label.is_empty() {
            output.push((
                item.id,
                format!("{}{}", "  ".repeat(depth), item.label),
                item.enabled,
            ));
        }
        flatten_menu_entries(&item.children, depth.saturating_add(1), output);
    }
}
