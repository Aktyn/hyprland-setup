use chrono::{Datelike, NaiveDate};
use gpui::{MouseButton, SharedString, div, prelude::*, px, rgb, rgba};

use super::theme::{foreground, muted, on_primary, outline, primary, surface, surface_high};

pub(crate) fn bar_button(label: impl Into<SharedString>, selected: bool) -> gpui::Div {
    let label = label.into();
    div()
        .px(px(9.))
        .py(px(5.))
        .rounded(px(12.))
        .bg(rgb(if selected { primary() } else { surface_high() }))
        .text_color(rgb(if selected { on_primary() } else { foreground() }))
        .text_size(px(12.))
        .child(label)
}

pub(crate) fn material_icon(icon: impl Into<SharedString>, size: f32, color: u32) -> gpui::Div {
    div()
        .font_family("Material Symbols Rounded")
        .text_size(px(size))
        .text_color(rgb(color))
        .child(icon.into())
}

pub(crate) fn app_icon_name(app_id: &str) -> &'static str {
    let app_id = app_id.to_lowercase();
    if app_id.contains("firefox")
        || app_id.contains("chrom")
        || app_id.contains("brave")
        || app_id.contains("browser")
    {
        "language"
    } else if app_id.contains("code") || app_id.contains("studio") {
        "code"
    } else if app_id.contains("kitty")
        || app_id.contains("foot")
        || app_id.contains("terminal")
        || app_id.contains("alacritty")
    {
        "terminal"
    } else if app_id.contains("discord") {
        "forum"
    } else if app_id.contains("spotify") || app_id.contains("music") {
        "music_note"
    } else if app_id.contains("obsidian") {
        "auto_stories"
    } else if app_id.contains("file") || app_id.contains("nautilus") {
        "folder"
    } else if app_id.contains("signal") || app_id.contains("telegram") || app_id.contains("slack") {
        "chat"
    } else if app_id.contains("steam") {
        "sports_esports"
    } else if app_id.contains("image") || app_id.contains("gimp") {
        "image"
    } else {
        "window"
    }
}

pub(crate) fn bar_icon_button(icon: &str, active: bool) -> gpui::Div {
    let active_background = rgba((primary() << 8) | 0x40);
    div()
        .w(px(32.))
        .h(px(32.))
        .rounded(px(16.))
        .flex()
        .items_center()
        .justify_center()
        .cursor_pointer()
        .bg(if active {
            active_background
        } else {
            rgba((surface_high() << 8) | 0)
        })
        .hover(|style| style.bg(rgba((surface_high() << 8) | 0x80)))
        .child(material_icon(
            icon,
            20.,
            if active { primary() } else { foreground() },
        ))
}

pub(crate) fn surface_card(title: impl Into<SharedString>, content: impl IntoElement) -> gpui::Div {
    let title = title.into();
    div()
        .w_full()
        .p(px(14.))
        .flex()
        .flex_col()
        .gap(px(10.))
        .bg(rgb(surface_high()))
        .rounded(px(16.))
        .border_1()
        .border_color(rgb(outline()))
        .child(
            div()
                .text_size(px(14.))
                .text_color(rgb(primary()))
                .child(title),
        )
        .child(content)
}

pub(crate) fn action_row(
    label: impl Into<SharedString>,
    detail: impl Into<SharedString>,
    action: impl Fn() + 'static,
) -> gpui::Div {
    let label = label.into();
    let detail = detail.into();
    div()
        .w_full()
        .px(px(12.))
        .py(px(10.))
        .flex()
        .items_center()
        .justify_between()
        .gap(px(12.))
        .bg(rgb(surface()))
        .rounded(px(12.))
        .on_mouse_down(MouseButton::Left, move |_, _, _| action())
        .child(action_row_content(label, detail))
}

pub(crate) fn action_row_content(
    label: impl Into<SharedString>,
    detail: impl Into<SharedString>,
) -> gpui::Div {
    let label = label.into();
    let detail = detail.into();
    div()
        .flex()
        .gap(px(12.))
        .child(
            div()
                .flex()
                .flex_col()
                .gap(px(2.))
                .child(
                    div()
                        .text_size(px(13.))
                        .text_color(rgb(foreground()))
                        .child(label),
                )
                .child(
                    div()
                        .text_size(px(11.))
                        .text_color(rgb(muted()))
                        .child(detail),
                ),
        )
        .child(
            div()
                .text_size(px(16.))
                .text_color(rgb(primary()))
                .child("›"),
        )
}

pub(crate) fn calendar_grid(month: NaiveDate, today: NaiveDate) -> gpui::Div {
    let first = month.with_day(1).unwrap_or(month);
    let start = first.weekday().num_days_from_monday() as i64;
    let next_month = if month.month() == 12 {
        NaiveDate::from_ymd_opt(month.year() + 1, 1, 1)
    } else {
        NaiveDate::from_ymd_opt(month.year(), month.month() + 1, 1)
    };
    let days = next_month
        .and_then(|date| date.pred_opt())
        .map(|date| date.day())
        .unwrap_or(30);
    let mut rows = Vec::new();
    let mut cells = Vec::new();
    for _ in 0..start {
        cells.push(String::new());
    }
    for day in 1..=days {
        cells.push(day.to_string());
    }
    while cells.len() % 7 != 0 {
        cells.push(String::new());
    }
    for week in cells.chunks(7) {
        rows.push(
            div()
                .w_full()
                .flex()
                .justify_between()
                .children(week.iter().map(|day| {
                    let is_today = month.year() == today.year()
                        && month.month() == today.month()
                        && day.parse::<u32>().ok() == Some(today.day());
                    div()
                        .w(px(32.))
                        .h(px(28.))
                        .flex()
                        .items_center()
                        .justify_center()
                        .rounded(px(9.))
                        .bg(rgb(if is_today { primary() } else { surface_high() }))
                        .text_color(rgb(if is_today { on_primary() } else { muted() }))
                        .text_size(px(11.))
                        .child(day.clone())
                })),
        );
    }
    div()
        .flex()
        .flex_col()
        .gap(px(4.))
        .child(div().flex().justify_between().children(
            ["M", "T", "W", "T", "F", "S", "S"].into_iter().map(|day| {
                div()
                    .w(px(32.))
                    .text_size(px(10.))
                    .text_color(rgb(muted()))
                    .child(day)
            }),
        ))
        .children(rows)
}
