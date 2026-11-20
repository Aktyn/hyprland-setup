use std::path::{Path, PathBuf};

use std::time::Duration;

use gpui::{
    Animation, AnimationExt, Context, MouseButton, Render, Window, div, ease_out_quint, img,
    prelude::*, px, rgb,
};

use crate::services::{Notification, NotificationService};

use super::{
    bar_button,
    theme::{foreground, muted, outline, primary, surface_high},
};

pub(crate) struct ShellNotificationToast {
    notifications: Vec<Notification>,
    service: NotificationService,
}

impl ShellNotificationToast {
    pub(crate) fn new(
        notifications: Vec<Notification>,
        service: NotificationService,
        _: &mut Context<Self>,
    ) -> Self {
        Self {
            notifications,
            service,
        }
    }

    pub(crate) fn set_notifications(
        &mut self,
        notifications: Vec<Notification>,
        cx: &mut Context<Self>,
    ) {
        if self.notifications != notifications {
            self.notifications = notifications;
            cx.notify();
        }
    }
}

impl Render for ShellNotificationToast {
    fn render(&mut self, _: &mut Window, _: &mut Context<Self>) -> impl IntoElement {
        let rows = self.notifications.iter().take(4).map(|notification| {
            let icon_path = Path::new(&notification.icon);
            let icon = icon_path
                .is_file()
                .then(|| img(PathBuf::from(icon_path)).size(px(32.)));
            let service = self.service.clone();
            let id = notification.id;
            let dismiss = bar_button("×", false)
                .on_mouse_down(MouseButton::Left, move |_, _, _| service.dismiss(id));
            let actions = notification
                .actions
                .iter()
                .map(|(key, label)| {
                    let service = self.service.clone();
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
                .p(px(12.))
                .rounded(px(14.))
                .bg(rgb(surface_high()))
                .border_1()
                .border_color(rgb(if notification.urgency == 2 {
                    primary()
                } else {
                    outline()
                }))
                .flex()
                .flex_col()
                .gap(px(7.))
                .when_some(icon, |row, icon| row.child(icon))
                .child(
                    div()
                        .flex()
                        .items_center()
                        .justify_between()
                        .gap(px(8.))
                        .child(
                            div()
                                .text_size(px(11.))
                                .text_color(rgb(muted()))
                                .child(notification.app_name.clone()),
                        )
                        .child(dismiss),
                )
                .child(
                    div()
                        .text_size(px(14.))
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
        div()
            .id("notification-toasts")
            .size_full()
            .p(px(8.))
            .flex()
            .flex_col()
            .items_end()
            .gap(px(8.))
            .children(rows)
            .with_animation(
                "aktyn-notification-toast-enter",
                Animation::new(Duration::from_millis(250)).with_easing(ease_out_quint()),
                |element, phase| {
                    element
                        .opacity(phase)
                        .relative()
                        .top(px(12. * (1. - phase)))
                },
            )
    }
}
