use std::{
    fs,
    path::{Path, PathBuf},
    process::Command,
    time::{Duration, Instant},
};

use chrono::{Datelike, Local, Months, NaiveDate};
use gpui::{
    Animation, AnimationExt, App, Context, Entity, FocusHandle, Focusable, KeyDownEvent,
    MouseButton, Render, SharedString, Window, div, ease_out_quint, img, prelude::*, px, rgb, rgba,
};

use crate::{
    config::{ConfigStore, SettingField, config_path},
    model::{ClipboardEntry, DesktopApp, MainTab, PanelKind},
    services::{
        Notification, NotificationService, control_media_player, copy_clipboard_entry, dispatch,
        fuzzy_score, launch_app, load_apps, notes_path, open_notes, read_clipboard_history,
        read_media_players, read_recent_apps, read_shortcuts, read_status, record_recent_app,
        run_detached, suspend_system, toggle_night_light,
    },
    ui::ShellBar,
};

use super::theme::{
    foreground, muted, outline, primary, surface, surface_high, surface_with_opacity,
};
use super::{
    action_row, action_row_content, app_icon_name, bar_button, calendar_grid, material_icon,
    surface_card,
};

#[derive(Clone, Copy, PartialEq)]
enum SettingsCategory {
    Appearance,
    Bar,
    Workspaces,
    Notifications,
    Battery,
}

pub(crate) struct ShellPanel {
    kind: PanelKind,
    tab: MainTab,
    parent: Entity<ShellBar>,
    config: Entity<ConfigStore>,
    notification_service: NotificationService,
    settings_category: SettingsCategory,
    apps: Vec<DesktopApp>,
    recent_apps: Vec<String>,
    clipboard: Vec<ClipboardEntry>,
    notifications: Vec<Notification>,
    shortcuts: Vec<(String, String)>,
    search_query: String,
    selected_app_index: usize,
    focus_handle: FocusHandle,
    focused_once: bool,
    stopwatch_running: bool,
    stopwatch_started: Option<Instant>,
    stopwatch_elapsed: Duration,
    timer_deadline: Option<Instant>,
    timer_duration: u64,
    timer_remaining: u64,
    timer_paused: bool,
    timer_finished: bool,
    calendar_month: NaiveDate,
}

impl ShellPanel {
    pub(crate) fn new(
        kind: PanelKind,
        parent: Entity<ShellBar>,
        config: Entity<ConfigStore>,
        notification_service: NotificationService,
        cx: &mut Context<Self>,
    ) -> Self {
        let mut panel = Self {
            kind,
            tab: MainTab::Apps,
            parent,
            config,
            notifications: notification_service.snapshot(),
            notification_service,
            settings_category: SettingsCategory::Appearance,
            apps: load_apps(),
            recent_apps: read_recent_apps(),
            clipboard: read_clipboard_history(),
            shortcuts: read_shortcuts(),
            search_query: String::new(),
            selected_app_index: 0,
            focus_handle: cx.focus_handle(),
            focused_once: false,
            stopwatch_running: false,
            stopwatch_started: None,
            stopwatch_elapsed: Duration::ZERO,
            timer_deadline: None,
            timer_duration: 5 * 60,
            timer_remaining: 5 * 60,
            timer_paused: false,
            timer_finished: false,
            calendar_month: Local::now()
                .date_naive()
                .with_day(1)
                .unwrap_or_else(|| Local::now().date_naive()),
        };
        if kind == PanelKind::Overview {
            panel.tab = MainTab::Apps;
        }

        let entity = cx.entity();
        cx.spawn(async move |_this, cx| {
            loop {
                cx.background_executor()
                    .timer(Duration::from_millis(500))
                    .await;
                cx.update(|cx| {
                    entity.update(cx, |panel, cx| {
                        if panel
                            .timer_deadline
                            .is_some_and(|deadline| Instant::now() >= deadline)
                        {
                            panel.timer_deadline = None;
                            panel.timer_remaining = 0;
                            panel.timer_paused = false;
                            panel.timer_finished = true;
                            run_detached(
                                "notify-send",
                                &["Timer finished!", "--urgency", "critical", "--transient"],
                            );
                        }
                        panel.notifications = panel.notification_service.snapshot();
                        cx.notify();
                    });
                });
            }
        })
        .detach();
        panel
    }

    fn close(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let parent = self.parent.clone();
        parent.update(cx, |bar, _| {
            bar.panel = None;
            bar.panel_kind = None;
        });
        window.remove_window();
    }

    fn toggle_stopwatch(&mut self, cx: &mut Context<Self>) {
        if self.stopwatch_running {
            if let Some(started) = self.stopwatch_started.take() {
                self.stopwatch_elapsed += started.elapsed();
            }
            self.stopwatch_running = false;
        } else {
            self.stopwatch_started = Some(Instant::now());
            self.stopwatch_running = true;
        }
        cx.notify();
    }

    fn reset_stopwatch(&mut self, cx: &mut Context<Self>) {
        self.stopwatch_running = false;
        self.stopwatch_started = None;
        self.stopwatch_elapsed = Duration::ZERO;
        cx.notify();
    }

    fn stopwatch_text(&self) -> String {
        let elapsed = self.stopwatch_elapsed
            + self
                .stopwatch_started
                .map(|started| started.elapsed())
                .unwrap_or_default();
        let seconds = elapsed.as_secs();
        format!(
            "{:02}:{:02}:{:02}",
            seconds / 3600,
            seconds / 60 % 60,
            seconds % 60
        )
    }

    fn start_timer(&mut self, cx: &mut Context<Self>) {
        if self.timer_remaining == 0 || self.timer_finished {
            self.timer_remaining = self.timer_duration;
        }
        self.timer_deadline = Some(Instant::now() + Duration::from_secs(self.timer_remaining));
        self.timer_paused = false;
        self.timer_finished = false;
        cx.notify();
    }

    fn toggle_timer_pause(&mut self, cx: &mut Context<Self>) {
        if let Some(deadline) = self.timer_deadline.take() {
            self.timer_remaining = deadline
                .saturating_duration_since(Instant::now())
                .as_secs_f64()
                .ceil() as u64;
            self.timer_paused = true;
        } else if self.timer_paused {
            self.timer_deadline = Some(Instant::now() + Duration::from_secs(self.timer_remaining));
            self.timer_paused = false;
        }
        cx.notify();
    }

    fn reset_timer(&mut self, cx: &mut Context<Self>) {
        self.timer_deadline = None;
        self.timer_remaining = self.timer_duration;
        self.timer_paused = false;
        self.timer_finished = false;
        cx.notify();
    }

    fn adjust_timer(&mut self, minutes: i64, cx: &mut Context<Self>) {
        if self.timer_deadline.is_some() {
            return;
        }
        self.timer_duration =
            (self.timer_duration as i64 + minutes * 60).clamp(60, 99 * 3600) as u64;
        self.timer_remaining = self.timer_duration;
        self.timer_finished = false;
        self.timer_paused = false;
        cx.notify();
    }

    fn dismiss_notifications(&mut self, cx: &mut Context<Self>) {
        self.notification_service.dismiss_all();
        self.notifications = self.notification_service.snapshot();
        cx.notify();
    }

    fn acknowledge_notifications(&mut self, cx: &mut Context<Self>) {
        self.notification_service.acknowledge_all();
        self.notifications = self.notification_service.snapshot();
        cx.notify();
    }

    fn matched_apps(&self) -> Vec<&DesktopApp> {
        if self.search_query.starts_with('!') {
            return Vec::new();
        }
        let query = self.search_query.trim_start_matches('!').trim();
        let mut matches = self
            .apps
            .iter()
            .filter_map(|app| {
                let score = if query.is_empty() {
                    1.0
                } else {
                    fuzzy_score(query, &app.name)
                        .or_else(|| fuzzy_score(query, &app.id))
                        .unwrap_or_default()
                };
                (query.is_empty() || score > 0.0).then_some((app, score))
            })
            .collect::<Vec<_>>();
        matches.sort_by(|(left, left_score), (right, right_score)| {
            if query.is_empty() {
                let left_recent = self.recent_apps.iter().rposition(|name| name == &left.name);
                let right_recent = self
                    .recent_apps
                    .iter()
                    .rposition(|name| name == &right.name);
                right_recent
                    .cmp(&left_recent)
                    .then_with(|| left.name.cmp(&right.name))
            } else {
                right_score
                    .total_cmp(left_score)
                    .then_with(|| left.name.cmp(&right.name))
            }
        });
        matches.into_iter().map(|(app, _)| app).collect()
    }

    fn launch_application(&mut self, id: &str, window: &mut Window, cx: &mut Context<Self>) {
        if !launch_app(id) {
            return;
        }
        if let Some(app) = self.apps.iter().find(|app| app.id == id) {
            self.recent_apps = record_recent_app(&app.name);
        }
        self.close(window, cx);
    }

    fn render_overview(&mut self, cx: &mut Context<Self>) -> gpui::Div {
        let entity = cx.entity();
        let tabs = [
            ("APPS", "apps", MainTab::Apps),
            ("TIME TOOLS", "acute", MainTab::TimeTools),
            ("OPTIONS", "dashboard", MainTab::Options),
        ];
        let current_tab = self.tab;
        let tab_buttons = tabs.into_iter().map(|(label, icon, tab)| {
            let selected = current_tab == tab;
            let entity = entity.clone();
            div()
                .px(px(12.))
                .pt(px(6.))
                .flex()
                .flex_col()
                .items_center()
                .gap(px(6.))
                .child(
                    div()
                        .flex()
                        .items_center()
                        .gap(px(8.))
                        .child(material_icon(
                            icon,
                            19.,
                            if selected { primary() } else { muted() },
                        ))
                        .child(
                            div()
                                .text_size(px(13.))
                                .text_color(rgb(if selected { primary() } else { muted() }))
                                .child(label),
                        ),
                )
                .child(
                    div()
                        .w_full()
                        .h(px(3.))
                        .rounded(px(2.))
                        .bg(rgba(if selected { (primary() << 8) | 0xff } else { 0 })),
                )
                .on_mouse_down(MouseButton::Left, move |_, _, cx| {
                    entity.update(cx, |panel, cx| {
                        panel.tab = tab;
                        cx.notify();
                    });
                })
        });

        let body = match self.tab {
            MainTab::Apps => self.render_apps(cx),
            MainTab::TimeTools => self.render_time_tools(cx),
            MainTab::Options => self.render_options(cx),
        };

        div()
            .w_full()
            .flex()
            .flex_col()
            .gap(px(8.))
            .child(div().w_full().flex().gap(px(8.)).children(tab_buttons))
            .child(body)
    }

    fn render_apps(&self, cx: &mut Context<Self>) -> gpui::Div {
        let matches = self.matched_apps();
        let no_results = matches.is_empty()
            && !self.search_query.is_empty()
            && !self.search_query.starts_with('!');
        let entity = cx.entity();
        let config = self.config.clone();
        let pinned_ids = self.config.read(cx).value.bar.pinned_apps.clone();
        let apps = matches.into_iter().enumerate().map(|(index, app)| {
            let id = app.id.clone();
            let launch = cx.listener(move |panel, _, window, cx| {
                panel.launch_application(&id, window, cx);
            });
            let app_id = app.id.clone();
            let panel = entity.clone();
            let config = config.clone();
            let pinned = pinned_ids.contains(&app_id);
            let selected = index == self.selected_app_index;
            let detail = app
                .comment
                .clone()
                .filter(|comment| !comment.trim().is_empty())
                .unwrap_or_else(|| app.id.clone());
            let icon = app
                .icon
                .clone()
                .map(|path| img(path).size(px(28.)).into_any_element())
                .unwrap_or_else(|| {
                    material_icon(app_icon_name(&app.id), 24., muted()).into_any_element()
                });
            div()
                .flex_1()
                .h(px(64.))
                .px(px(10.))
                .flex()
                .items_center()
                .gap(px(8.))
                .bg(rgb(if pinned { surface_high() } else { surface() }))
                .border_1()
                .border_color(if selected || pinned {
                    rgb(if selected { primary() } else { outline() })
                } else {
                    rgba(0)
                })
                .rounded(px(8.))
                .hover(|style| style.border_color(rgb(primary())))
                .on_mouse_down(MouseButton::Left, launch)
                .on_mouse_down(MouseButton::Right, move |_, _, cx| {
                    config.update(cx, |store, cx| {
                        let pinned = &mut store.value.bar.pinned_apps;
                        if let Some(index) = pinned.iter().position(|id| id == &app_id) {
                            pinned.remove(index);
                        } else {
                            pinned.push(app_id.clone());
                        }
                        store.save();
                        cx.notify();
                    });
                    panel.update(cx, |_, cx| cx.notify());
                })
                .child(icon)
                .child(
                    div()
                        .flex_1()
                        .flex()
                        .flex_col()
                        .gap(px(2.))
                        .child(
                            div()
                                .truncate()
                                .text_size(px(13.))
                                .text_color(rgb(foreground()))
                                .child(app.name.clone()),
                        )
                        .child(
                            div()
                                .truncate()
                                .text_size(px(10.))
                                .text_color(rgb(muted()))
                                .child(detail),
                        ),
                )
        });
        let mut app_rows = Vec::new();
        let mut apps = apps.into_iter();
        while let Some(left) = apps.next() {
            let right = apps.next().unwrap_or_else(|| div().flex_1().h(px(64.)));
            app_rows.push(div().w_full().flex().gap(px(8.)).child(left).child(right));
        }
        let run_command = self.search_query.starts_with('!') && self.search_query.len() > 1;
        let command = self.search_query.trim_start_matches('!').trim().to_owned();
        let run_row = run_command.then(|| {
            let command_to_run = command.clone();
            let listener = cx.listener(move |panel, _, window, cx| {
                run_detached("bash", &["-c", &command_to_run]);
                panel.close(window, cx);
            });
            div()
                .w_full()
                .px(px(12.))
                .py(px(10.))
                .rounded(px(12.))
                .bg(rgb(surface_high()))
                .on_mouse_down(MouseButton::Left, listener)
                .child(action_row_content("Run command", command.clone()))
        });
        let search_hint = if self.search_query.is_empty() {
            "Search or calculate. \"!\" to run commands".to_owned()
        } else {
            self.search_query.clone()
        };
        let search = div()
            .w_full()
            .h(px(48.))
            .px(px(12.))
            .flex()
            .items_center()
            .gap(px(10.))
            .bg(rgb(surface_high()))
            .border_1()
            .border_color(rgb(outline()))
            .rounded(px(8.))
            .child(material_icon("search", 20., muted()))
            .child(
                div()
                    .flex_1()
                    .truncate()
                    .text_size(px(13.))
                    .text_color(rgb(if self.search_query.is_empty() {
                        muted()
                    } else {
                        foreground()
                    }))
                    .child(search_hint),
            );
        let app_grid = div()
            .id("shell-app-grid")
            .w_full()
            .max_h(px(640.))
            .overflow_y_scroll()
            .flex()
            .flex_col()
            .gap(px(8.))
            .children(app_rows)
            .when(no_results, |grid| {
                grid.child(
                    div()
                        .w_full()
                        .py(px(20.))
                        .text_color(rgb(muted()))
                        .text_size(px(13.))
                        .child("No matching apps"),
                )
            });
        let mut app_list = div().w_full().flex().flex_col().gap(px(12.)).child(search);
        if let Some(run_row) = run_row {
            app_list = app_list.child(run_row);
        }
        app_list.child(app_grid)
    }

    fn on_key_down(&mut self, event: &KeyDownEvent, window: &mut Window, cx: &mut Context<Self>) {
        if event.keystroke.modifiers.control
            || event.keystroke.modifiers.alt
            || event.keystroke.modifiers.platform
        {
            return;
        }

        match event.keystroke.key.to_ascii_lowercase().as_str() {
            "escape" => self.close(window, cx),
            "arrowdown"
                if self.kind == PanelKind::Overview && matches!(self.tab, MainTab::Apps) =>
            {
                self.selected_app_index = self
                    .selected_app_index
                    .saturating_add(1)
                    .min(self.matched_apps().len().saturating_sub(1));
                cx.notify();
            }
            "arrowup" if self.kind == PanelKind::Overview && matches!(self.tab, MainTab::Apps) => {
                self.selected_app_index = self.selected_app_index.saturating_sub(1);
                cx.notify();
            }
            "backspace"
                if self.kind == PanelKind::Overview && matches!(self.tab, MainTab::Apps) =>
            {
                self.search_query.pop();
                self.selected_app_index = 0;
                cx.notify();
            }
            "enter" if self.kind == PanelKind::Overview && matches!(self.tab, MainTab::Apps) => {
                if self.search_query.starts_with('!') && self.search_query.len() > 1 {
                    run_detached(
                        "bash",
                        &["-c", self.search_query.trim_start_matches('!').trim()],
                    );
                    self.close(window, cx);
                } else if let Some(app) = self.matched_apps().get(self.selected_app_index) {
                    let id = app.id.clone();
                    self.launch_application(&id, window, cx);
                }
            }
            _ if self.kind == PanelKind::Overview && matches!(self.tab, MainTab::Apps) => {
                if let Some(text) = event
                    .keystroke
                    .key_char
                    .as_ref()
                    .filter(|text| !text.is_empty() && !text.chars().any(char::is_control))
                {
                    self.search_query.push_str(text);
                    self.selected_app_index = 0;
                    cx.notify();
                }
            }
            _ => {}
        }
    }

    fn render_time_tools(&mut self, cx: &mut Context<Self>) -> gpui::Div {
        let now = Local::now();
        let stopwatch = self.stopwatch_text();
        let stopwatch_label = if self.stopwatch_running {
            "Running"
        } else {
            "Paused"
        };
        let timer_seconds = self
            .timer_deadline
            .map(|deadline| deadline.saturating_duration_since(Instant::now()).as_secs())
            .unwrap_or(self.timer_remaining);
        let timer_label = if self.timer_finished {
            "Timer finished".into()
        } else {
            format!(
                "{:02}:{:02}:{:02}",
                timer_seconds / 3600,
                timer_seconds / 60 % 60,
                timer_seconds % 60
            )
        };
        let timer_detail = if self.timer_deadline.is_some() {
            "Countdown running"
        } else if self.timer_paused {
            "Countdown paused"
        } else {
            "Choose a duration"
        };

        let calendar_month = self.calendar_month;
        let previous_month = cx.listener(move |panel, _, _, cx| {
            if let Some(month) = panel.calendar_month.checked_sub_months(Months::new(1)) {
                panel.calendar_month = month;
                cx.notify();
            }
        });
        let next_month = cx.listener(|panel, _, _, cx| {
            if let Some(month) = panel.calendar_month.checked_add_months(Months::new(1)) {
                panel.calendar_month = month;
                cx.notify();
            }
        });
        let calendar = calendar_grid(calendar_month, now.date_naive());
        let clock_panel = surface_card(
            now.format("%A, %d %B").to_string(),
            div()
                .flex()
                .flex_col()
                .gap(px(10.))
                .child(
                    div()
                        .text_size(px(28.))
                        .text_color(rgb(foreground()))
                        .child(now.format("%H:%M:%S").to_string()),
                )
                .child(
                    div()
                        .flex()
                        .items_center()
                        .justify_between()
                        .child(
                            bar_button("‹", false).on_mouse_down(MouseButton::Left, previous_month),
                        )
                        .child(
                            div()
                                .text_size(px(13.))
                                .text_color(rgb(foreground()))
                                .child(calendar_month.format("%B %Y").to_string()),
                        )
                        .child(bar_button("›", false).on_mouse_down(MouseButton::Left, next_month)),
                )
                .child(calendar),
        );
        let stopwatch_row = div()
            .w_full()
            .px(px(12.))
            .py(px(10.))
            .flex()
            .items_center()
            .justify_between()
            .gap(px(12.))
            .rounded(px(12.))
            .bg(rgb(surface()))
            .child(action_row_content(stopwatch, stopwatch_label))
            .child(
                div()
                    .flex()
                    .items_center()
                    .gap(px(6.))
                    .child(
                        bar_button(
                            if self.stopwatch_running {
                                "Pause"
                            } else {
                                "Start"
                            },
                            true,
                        )
                        .on_mouse_down(
                            MouseButton::Left,
                            cx.listener(|panel, _, _, cx| panel.toggle_stopwatch(cx)),
                        ),
                    )
                    .child(bar_button("Reset", false).on_mouse_down(
                        MouseButton::Left,
                        cx.listener(|panel, _, _, cx| panel.reset_stopwatch(cx)),
                    )),
            );
        let timer_row = div()
            .flex()
            .flex_col()
            .gap(px(8.))
            .child(action_row_content(timer_label, timer_detail))
            .child(
                div()
                    .flex()
                    .items_center()
                    .justify_center()
                    .gap(px(8.))
                    .child(bar_button("−1m", false).on_mouse_down(
                        MouseButton::Left,
                        cx.listener(|panel, _, _, cx| panel.adjust_timer(-1, cx)),
                    ))
                    .child(
                        bar_button(
                            if self.timer_deadline.is_some() {
                                "Pause"
                            } else if self.timer_paused {
                                "Resume"
                            } else {
                                "Start"
                            },
                            true,
                        )
                        .on_mouse_down(
                            MouseButton::Left,
                            cx.listener(|panel, _, _, cx| {
                                if panel.timer_deadline.is_some() || panel.timer_paused {
                                    panel.toggle_timer_pause(cx);
                                } else {
                                    panel.start_timer(cx);
                                }
                            }),
                        ),
                    )
                    .child(bar_button("Reset", false).on_mouse_down(
                        MouseButton::Left,
                        cx.listener(|panel, _, _, cx| panel.reset_timer(cx)),
                    ))
                    .child(bar_button("+1m", false).on_mouse_down(
                        MouseButton::Left,
                        cx.listener(|panel, _, _, cx| panel.adjust_timer(1, cx)),
                    )),
            );
        let tools = surface_card(
            "Timer and stopwatch",
            div()
                .flex()
                .flex_col()
                .gap(px(8.))
                .child(stopwatch_row)
                .child(timer_row),
        );

        div()
            .w_full()
            .flex()
            .flex_col()
            .gap(px(12.))
            .child(clock_panel)
            .child(tools)
    }

    fn select_wallpaper(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let config = self.config.clone();
        let panel = cx.entity();
        cx.spawn(async move |_, cx| {
            let result = tokio::task::spawn_blocking(|| {
                let home = std::env::var("HOME").unwrap_or_default();
                Command::new("kdialog")
                    .args([
                        "--getopenfilename",
                        &format!("{home}/Pictures"),
                        "Images (*.png *.jpg *.jpeg *.gif *.bmp *.webp *.tif *.tiff *.svg);;All files (*)",
                    ])
                    .output()
            })
            .await;
            match result {
                Ok(Ok(output)) if output.status.success() => {
                    let path = String::from_utf8_lossy(&output.stdout).trim().to_owned();
                    if !path.is_empty() {
                        cx.update(|cx| {
                            config.update(cx, |store, cx| {
                                store.value.wallpaper.path = path.clone();
                                crate::ui::theme::sync_theme_with_wallpaper(Some(&path));
                                store.save();
                                cx.notify();
                            });
                            panel.update(cx, |_, cx| cx.notify());
                        });
                    }
                }
                Ok(Ok(_)) => {}
                Ok(Err(error)) => eprintln!("Could not open wallpaper picker: {error}"),
                Err(error) => eprintln!("Wallpaper picker task failed: {error}"),
            }
        })
        .detach();
        self.close(window, cx);
    }

    fn render_options(&mut self, cx: &mut Context<Self>) -> gpui::Div {
        let config = self.config.read(cx).value.clone();
        let select_wallpaper = cx.listener(|panel, _, window, cx| {
            panel.select_wallpaper(window, cx);
        });
        let mut quick_actions = div().flex().flex_col().gap(px(6.));
        if !config.general.hide_author_link {
            quick_actions = quick_actions.child(action_row(
                "More about the author",
                "Open Aktyn on GitHub",
                || run_detached("xdg-open", &["https://github.com/Aktyn"]),
            ));
        }
        div()
            .w_full()
            .flex()
            .flex_col()
            .gap(px(10.))
            .child(surface_card(
                "Quick actions",
                quick_actions
                    .child(action_row(
                        "Open config file",
                        config_path().display().to_string(),
                        || {
                            run_detached("xdg-open", &[config_path().to_string_lossy().as_ref()]);
                        },
                    ))
                    .child(action_row(
                        "Open settings",
                        "Appearance, bar, battery and more",
                        || {
                            run_detached("aktyn-shell", &["--settings"]);
                        },
                    ))
                    .child(
                        div()
                            .w_full()
                            .px(px(12.))
                            .py(px(10.))
                            .rounded(px(12.))
                            .bg(rgb(surface()))
                            .on_mouse_down(MouseButton::Left, select_wallpaper)
                            .child(action_row_content(
                                "Select wallpaper",
                                if config.wallpaper.path.is_empty() {
                                    "No wallpaper selected"
                                } else {
                                    &config.wallpaper.path
                                },
                            )),
                    )
                    .child(action_row(
                        "Night light",
                        "Toggle hyprsunset",
                        toggle_night_light,
                    ))
                    .child(action_row("Bluetooth", "Manage nearby devices", || {
                        run_detached("blueman-manager", &[]);
                    }))
                    .child(action_row(
                        "Screenshot region",
                        "Capture to clipboard",
                        || {
                            run_detached(
                                "hyprshot",
                                &[
                                    "--freeze",
                                    "--clipboard-only",
                                    "--mode",
                                    "region",
                                    "--silent",
                                ],
                            );
                        },
                    ))
                    .child(action_row("Pick a color", "Copy selected color", || {
                        run_detached("hyprpicker", &["-a"]);
                    })),
            ))
            .child(surface_card(
                "System",
                div()
                    .flex()
                    .flex_col()
                    .gap(px(6.))
                    .child(action_row(
                        "Check for updates",
                        "Open package update checker",
                        || {
                            run_detached("kitty", &["--hold", "fish", "-c", "checkupdates"]);
                        },
                    ))
                    .child(action_row(
                        "Clipboard history",
                        "Search copied items",
                        || {
                            run_detached("aktyn-shell", &["--clipboard"]);
                        },
                    ))
                    .child(action_row(
                        "Notes",
                        "Open your local notes file",
                        open_notes,
                    ))
                    .child(action_row("Session", "Lock, log out, or power off", || {
                        run_detached("aktyn-shell", &["--session"]);
                    })),
            ))
    }

    fn render_clipboard(&self) -> gpui::Div {
        let rows = self.clipboard.iter().take(30).map(|entry| {
            let id = entry.id.clone();
            action_row(
                entry.text.chars().take(72).collect::<String>(),
                "Copy to clipboard",
                move || copy_clipboard_entry(&id),
            )
        });
        surface_card(
            "Recent items",
            div().flex().flex_col().gap(px(6.)).children(rows),
        )
    }

    fn render_cheatsheet(&self) -> gpui::Div {
        let rows = if self.shortcuts.is_empty() {
            vec![action_row(
                "Could not read keybindings",
                "Check that `hyprctl binds -j` is available",
                || {},
            )]
        } else {
            self.shortcuts
                .iter()
                .map(|(key, description)| action_row(key.clone(), description.clone(), || {}))
                .collect()
        };
        surface_card(
            "Current Hyprland keybindings",
            div().flex().flex_col().gap(px(6.)).children(rows),
        )
    }

    fn render_notifications(&self, cx: &mut Context<Self>) -> gpui::Div {
        let rows = self.notifications.iter().take(64).map(|notification| {
            let icon_path = Path::new(&notification.icon);
            let icon = (icon_path.is_file()).then(|| img(PathBuf::from(icon_path)).size(px(28.)));
            let timestamp = chrono::DateTime::<Local>::from(notification.created_at)
                .format("%H:%M")
                .to_string();
            let actions = notification
                .actions
                .iter()
                .map(|(key, label)| {
                    let service = self.notification_service.clone();
                    let key = key.clone();
                    let id = notification.id;
                    bar_button(label.clone(), false)
                        .on_mouse_down(MouseButton::Left, move |_, _, _| {
                            service.invoke_action(id, key.clone())
                        })
                })
                .collect::<Vec<_>>();
            div()
                .w_full()
                .p(px(10.))
                .rounded(px(12.))
                .bg(rgb(if notification.unread {
                    surface_high()
                } else {
                    surface()
                }))
                .border_1()
                .border_color(rgb(if notification.urgency == 2 {
                    primary()
                } else {
                    outline()
                }))
                .flex()
                .flex_col()
                .gap(px(5.))
                .when_some(icon, |row, icon| row.child(icon))
                .child(
                    div()
                        .flex()
                        .justify_between()
                        .text_size(px(11.))
                        .text_color(rgb(muted()))
                        .child(notification.app_name.clone())
                        .child(timestamp),
                )
                .child(
                    div()
                        .text_size(px(13.))
                        .text_color(rgb(foreground()))
                        .child(notification.summary.clone()),
                )
                .when(!notification.body.is_empty(), |row| {
                    row.child(
                        div()
                            .text_size(px(12.))
                            .text_color(rgb(muted()))
                            .child(notification.body.clone()),
                    )
                })
                .when(notification.unread, |row| row.children(actions))
        });
        let unread = self
            .notifications
            .iter()
            .any(|notification| notification.unread);
        let dismiss = div()
            .w_full()
            .px(px(12.))
            .py(px(10.))
            .rounded(px(12.))
            .bg(rgb(surface()))
            .on_mouse_down(
                MouseButton::Left,
                cx.listener(|panel, _, _, cx| panel.dismiss_notifications(cx)),
            )
            .child(action_row_content(
                "Clear all notifications",
                "Remove notification history",
            ));
        let acknowledge = unread.then(|| {
            div()
                .w_full()
                .px(px(12.))
                .py(px(10.))
                .rounded(px(12.))
                .bg(rgb(surface()))
                .on_mouse_down(
                    MouseButton::Left,
                    cx.listener(|panel, _, _, cx| panel.acknowledge_notifications(cx)),
                )
                .child(action_row_content(
                    "Acknowledge all",
                    "Mark notifications as read",
                ))
        });
        surface_card(
            "Recent notifications",
            div()
                .flex()
                .flex_col()
                .gap(px(6.))
                .when(self.notifications.is_empty(), |rows| {
                    rows.child(action_row(
                        "No notifications",
                        "You're all caught up",
                        || {},
                    ))
                })
                .when_some(acknowledge, |rows, button| rows.child(button))
                .child(dismiss)
                .children(rows),
        )
    }

    fn render_notes(&self) -> gpui::Div {
        let note = notes_path();
        let excerpt = fs::read_to_string(&note)
            .unwrap_or_else(|_| "Your notes file will be created when you open it.".into());
        surface_card(
            "Quick notes",
            div()
                .flex()
                .flex_col()
                .gap(px(10.))
                .child(
                    div()
                        .max_h(px(180.))
                        .text_size(px(12.))
                        .text_color(rgb(muted()))
                        .child(excerpt.chars().take(500).collect::<String>()),
                )
                .child(action_row(
                    "Edit notes",
                    note.display().to_string(),
                    open_notes,
                )),
        )
    }

    fn setting_stepper(
        &self,
        cx: &mut Context<Self>,
        label: &'static str,
        description: &'static str,
        field: SettingField,
        value: String,
    ) -> gpui::Div {
        let panel = cx.entity();
        let decrement_config = self.config.clone();
        let decrement_panel = panel.clone();
        let increment_config = self.config.clone();
        let decrement = div()
            .px(px(10.))
            .py(px(4.))
            .rounded(px(8.))
            .bg(rgb(surface()))
            .text_color(rgb(foreground()))
            .child("−")
            .on_mouse_down(MouseButton::Left, move |_, _, cx| {
                decrement_config.update(cx, |store, cx| {
                    store.adjust(field, -1);
                    store.save();
                    cx.notify();
                });
                decrement_panel.update(cx, |_, cx| cx.notify());
            });
        let increment_panel = panel;
        let increment = div()
            .px(px(10.))
            .py(px(4.))
            .rounded(px(8.))
            .bg(rgb(surface()))
            .text_color(rgb(foreground()))
            .child("+")
            .on_mouse_down(MouseButton::Left, move |_, _, cx| {
                increment_config.update(cx, |store, cx| {
                    store.adjust(field, 1);
                    store.save();
                    cx.notify();
                });
                increment_panel.update(cx, |_, cx| cx.notify());
            });
        div()
            .w_full()
            .px(px(12.))
            .py(px(10.))
            .flex()
            .items_center()
            .justify_between()
            .gap(px(8.))
            .rounded(px(12.))
            .bg(rgb(surface()))
            .child(
                div()
                    .flex_1()
                    .flex()
                    .flex_col()
                    .gap(px(3.))
                    .child(div().text_size(px(13.)).child(label))
                    .child(
                        div()
                            .text_size(px(11.))
                            .text_color(rgb(muted()))
                            .child(description),
                    ),
            )
            .child(
                div()
                    .flex()
                    .items_center()
                    .gap(px(8.))
                    .child(decrement)
                    .child(
                        div()
                            .min_w(px(54.))
                            .text_size(px(12.))
                            .text_color(rgb(primary()))
                            .child(value),
                    )
                    .child(increment),
            )
    }

    fn setting_toggle(
        &self,
        cx: &mut Context<Self>,
        label: &'static str,
        description: impl Into<SharedString>,
        field: SettingField,
        checked: bool,
    ) -> gpui::Div {
        let description = description.into();
        let config = self.config.clone();
        let panel = cx.entity();
        div()
            .w_full()
            .px(px(12.))
            .py(px(10.))
            .flex()
            .items_center()
            .justify_between()
            .gap(px(8.))
            .rounded(px(12.))
            .bg(rgb(surface()))
            .child(
                div()
                    .flex_1()
                    .flex()
                    .flex_col()
                    .gap(px(3.))
                    .child(div().text_size(px(13.)).child(label))
                    .child(
                        div()
                            .text_size(px(11.))
                            .text_color(rgb(muted()))
                            .child(description),
                    ),
            )
            .child(bar_button(if checked { "ON" } else { "OFF" }, checked))
            .on_mouse_down(MouseButton::Left, move |_, _, cx| {
                config.update(cx, |store, cx| {
                    store.toggle(field);
                    store.save();
                    cx.notify();
                });
                panel.update(cx, |_, cx| cx.notify());
            })
    }

    fn render_settings(&mut self, cx: &mut Context<Self>) -> gpui::Div {
        let config = self.config.read(cx).value.clone();
        let settings = match self.settings_category {
            SettingsCategory::Appearance => div()
                .flex()
                .flex_col()
                .gap(px(8.))
                .child(self.setting_toggle(
                    cx,
                    "Hide author link",
                    "Hide the author link from the options panel.",
                    SettingField::HideAuthorLink,
                    config.general.hide_author_link,
                ))
                .child(self.setting_stepper(
                    cx,
                    "Panels transparency",
                    "Transparency of the bar and shell panels.",
                    SettingField::Transparency,
                    format!("{:.0}%", config.general.panels_transparency * 100.),
                )),
            SettingsCategory::Bar => div()
                .flex()
                .flex_col()
                .gap(px(8.))
                .child(self.setting_stepper(
                    cx,
                    "Bar height",
                    "Height in pixels.",
                    SettingField::BarHeight,
                    format!("{} px", config.bar.height),
                ))
                .child(self.setting_stepper(
                    cx,
                    "Shadow opacity",
                    "Opacity of the bar shadow.",
                    SettingField::ShadowOpacity,
                    format!("{:.0}%", config.bar.shadow_opacity * 100.),
                ))
                .child(self.setting_stepper(
                    cx,
                    "Tray icon desaturation",
                    "Amount of desaturation applied to status icons.",
                    SettingField::TrayDesaturation,
                    format!("{:.0}%", config.bar.desaturate_tray_icons * 100.),
                ))
                .child(self.setting_stepper(
                    cx,
                    "Panel animation",
                    "Panel slide duration in milliseconds.",
                    SettingField::PanelAnimation,
                    format!("{} ms", config.bar.panel_slide_duration),
                )),
            SettingsCategory::Workspaces => {
                div()
                    .flex()
                    .flex_col()
                    .gap(px(8.))
                    .child(self.setting_stepper(
                        cx,
                        "Number of workspaces",
                        "How many workspaces are shown on the bar.",
                        SettingField::WorkspaceCount,
                        config.workspaces.count.to_string(),
                    ))
            }
            SettingsCategory::Notifications => {
                div()
                    .flex()
                    .flex_col()
                    .gap(px(8.))
                    .child(self.setting_stepper(
                        cx,
                        "Default timeout",
                        "Notification lifetime in milliseconds.",
                        SettingField::NotificationTimeout,
                        format!("{} ms", config.notifications.default_timeout),
                    ))
            }
            SettingsCategory::Battery => div()
                .flex()
                .flex_col()
                .gap(px(8.))
                .child(self.setting_stepper(
                    cx,
                    "Low battery threshold",
                    "Show a warning at this battery level.",
                    SettingField::BatteryLow,
                    format!("{}%", config.battery.low),
                ))
                .child(self.setting_stepper(
                    cx,
                    "Critical battery threshold",
                    "Show a critical warning at this level.",
                    SettingField::BatteryCritical,
                    format!("{}%", config.battery.critical),
                ))
                .child(self.setting_stepper(
                    cx,
                    "Automatic suspend threshold",
                    "Suspend when unplugged and the battery reaches this level.",
                    SettingField::BatterySuspend,
                    format!("{}%", config.battery.suspend),
                ))
                .child(self.setting_toggle(
                    cx,
                    "Automatic suspend",
                    format!("Suspend at {}% when unplugged.", config.battery.suspend),
                    SettingField::AutomaticSuspend,
                    config.battery.automatic_suspend,
                )),
        };
        let entity = cx.entity();
        let categories = [
            ("Appearance", SettingsCategory::Appearance),
            ("Bar", SettingsCategory::Bar),
            ("Workspaces", SettingsCategory::Workspaces),
            ("Notifications", SettingsCategory::Notifications),
            ("Battery", SettingsCategory::Battery),
        ]
        .into_iter()
        .map(|(label, category)| {
            let selected = self.settings_category == category;
            let entity = entity.clone();
            bar_button(label, selected).on_mouse_down(MouseButton::Left, move |_, _, cx| {
                entity.update(cx, |panel, cx| {
                    panel.settings_category = category;
                    cx.notify();
                });
            })
        });
        div()
            .w_full()
            .flex()
            .flex_col()
            .gap(px(12.))
            .child(div().flex().gap(px(6.)).children(categories))
            .child(surface_card("Settings", settings))
    }

    fn render_audio(&self) -> gpui::Div {
        let status = read_status();
        let players = read_media_players();
        let volume = status
            .volume
            .map(|value| format!("Current volume: {value}%"))
            .unwrap_or_else(|| "Audio service unavailable".into());
        let mut content = div()
            .flex()
            .flex_col()
            .gap(px(8.))
            .child(action_row("Volume", &volume, || {}))
            .child(action_row("Volume down", "Decrease by 5%", || {
                run_detached("wpctl", &["set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"]);
            }))
            .child(action_row("Volume up", "Increase by 5%", || {
                run_detached(
                    "wpctl",
                    &["set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", "5%+"],
                );
            }))
            .child(action_row("Mute output", "Toggle default sink", || {
                run_detached("wpctl", &["set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
            }))
            .child(action_row(
                "Mute microphone",
                "Toggle default source",
                || {
                    run_detached("wpctl", &["set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]);
                },
            ));
        if players.is_empty() {
            content = content.child(action_row(
                "No active media player",
                "Open an MPRIS-compatible player",
                || {},
            ));
        } else {
            for player in players {
                let player_name = player.name.clone();
                content = content.child(action_row(
                    player.title,
                    format!("{} · Previous track", player.name),
                    move || control_media_player(&player_name, "previous"),
                ));
                let player_name = player.name.clone();
                content =
                    content.child(action_row("Play / pause", player.name.clone(), move || {
                        control_media_player(&player_name, "play-pause")
                    }));
                let player_name = player.name.clone();
                content = content.child(action_row("Next track", player.name, move || {
                    control_media_player(&player_name, "next")
                }));
            }
        }
        surface_card("Sound output", content)
    }

    fn render_session(&self) -> gpui::Div {
        surface_card(
            "Power and session",
            div()
                .flex()
                .flex_col()
                .gap(px(8.))
                .child(action_row("Lock screen", "Start Hyprlock", || {
                    run_detached("hyprlock", &[]);
                }))
                .child(action_row("Log out", "Exit Hyprland", || {
                    dispatch(&["dispatch", "exit"]);
                }))
                .child(action_row("Suspend", "Suspend this computer", || {
                    suspend_system();
                }))
                .child(action_row("Restart", "Reboot this computer", || {
                    run_detached("systemctl", &["reboot"]);
                }))
                .child(action_row("Power off", "Shut down this computer", || {
                    run_detached("systemctl", &["poweroff"]);
                })),
        )
    }
}

impl Render for ShellPanel {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        if !self.focused_once {
            self.focus_handle.focus(window, cx);
            self.focused_once = true;
        }
        let config = self.config.read(cx).value.clone();
        let surface = surface_with_opacity(config.general.panels_transparency);
        let close = cx.listener(|this, _, window, cx| this.close(window, cx));
        let content = match self.kind {
            PanelKind::Overview => self.render_overview(cx),
            PanelKind::Clipboard => self.render_clipboard(),
            PanelKind::Cheatsheet => self.render_cheatsheet(),
            PanelKind::Notifications => self.render_notifications(cx),
            PanelKind::Notes => self.render_notes(),
            PanelKind::Settings => self.render_settings(cx),
            PanelKind::Audio => self.render_audio(),
            PanelKind::Session => self.render_session(),
        };
        let titlebar = (self.kind != PanelKind::Overview).then(|| {
            div()
                .flex()
                .items_center()
                .justify_between()
                .child(
                    div()
                        .text_size(px(18.))
                        .text_color(rgb(foreground()))
                        .child(self.kind.title()),
                )
                .child(bar_button("×", false).on_mouse_down(MouseButton::Left, close))
        });
        let panel = div()
            .w_full()
            .h_full()
            .p(px(14.))
            .flex()
            .flex_col()
            .gap(px(14.))
            .bg(surface)
            .when(self.kind != PanelKind::Overview, |panel| {
                panel.border_1().border_color(rgb(outline()))
            })
            .rounded_tl(if self.kind == PanelKind::Overview {
                px(0.)
            } else {
                px(22.)
            })
            .rounded_tr(if self.kind == PanelKind::Overview {
                px(0.)
            } else {
                px(22.)
            })
            .rounded_bl(px(22.))
            .rounded_br(px(22.))
            .text_color(rgb(foreground()))
            .track_focus(&self.focus_handle)
            .when_some(titlebar, |panel, titlebar| panel.child(titlebar))
            .child(
                div()
                    .id("shell-panel-scroll")
                    .flex_1()
                    .overflow_y_scroll()
                    .child(content),
            );
        gpui::InteractiveElement::on_key_down(
            panel,
            cx.listener(|this, event, window, cx| this.on_key_down(event, window, cx)),
        )
        .with_animation(
            "aktyn-panel-enter",
            Animation::new(Duration::from_millis(config.bar.panel_slide_duration))
                .with_easing(ease_out_quint()),
            |element, phase| element.opacity(phase).relative().top(px(8. * (1. - phase))),
        )
    }
}

impl Focusable for ShellPanel {
    fn focus_handle(&self, _: &App) -> FocusHandle {
        self.focus_handle.clone()
    }
}
