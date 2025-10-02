pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

import "../common"

Singleton {
  id: notificationsRoot

  component NotificationObject: QtObject {
    id: wrapper

    required property Notification notificationHandle
    required property int id
    required property string summary
    property string body
    property string icon
    property int urgency

    property bool isNew: true
    property double time: 0
    property int timeout: Config.notifications.defaultTimeout

    property Timer timer

    property var removeFromList

    function acknowledge(expired = false) {
      wrapper.isNew = false;

      if (expired) {
        wrapper.notificationHandle?.expire();
      }

      if (wrapper.notificationHandle?.transient && wrapper.removeFromList && typeof wrapper.removeFromList === "function") {
        wrapper.removeFromList();
      }
    }
  }
  component NotificationTimer: Timer {
    required property NotificationObject notificationObject

    interval: Config.notifications.defaultTimeout
    running: true
    onTriggered: function () {
      this.notificationObject.acknowledge(true);
      this.destroy();
    }
  }

  property int notificationsHistoryLimit: 64
  property list<NotificationObject> list: []
  property bool hasUnread: list.some(n => n.isNew)

  function destroyNotification(notificationObject: NotificationObject) {
    notificationObject.timer?.stop();
    notificationObject.notificationHandle?.dismiss();
    notificationObject.destroy();
  }

  function clearAll() {
    for (const notificationObject of notificationsRoot.list) {
      notificationsRoot.destroyNotification(notificationObject);
    }
    notificationsRoot.list = [];
  }

  signal notify(notification: NotificationObject)

  //NOTE: make sure there is no notification service running (e.g.: swaync) that blocks org.freedesktop.Notifications dbus
  NotificationServer {
    onNotification: function (notification) {
      notification.tracked = true;

      const expireTimeout = notification.expireTimeout <= 0 ? Config.notifications.defaultTimeout : notification.expireTimeout;
      const realTimeout = notification.urgency === NotificationUrgency.Critical ? ~(1 << 31) : expireTimeout;

      const notificationObject = notificationObjectComponent.createObject(notificationsRoot, {
        notificationHandle: notification,
        id: notification.id,
        summary: notification.summary,
        body: notification.body,
        icon: notification.image || notification.appIcon,
        urgency: notification.urgency,
        time: Date.now(),
        timeout: realTimeout,
        removeFromList: function () {
          notificationsRoot.list = notificationsRoot.list.filter(n => n !== notificationObject);
          notificationsRoot.destroyNotification(notificationObject);
        }
      });

      if (notification.urgency !== NotificationUrgency.Critical) {
        notificationObject.timer = notificationTimerComponent.createObject(notificationsRoot, {
          notificationObject: notificationObject,
          interval: expireTimeout
        });
      }

      notificationsRoot.list = [notificationObject, ...notificationsRoot.list];
      while (notificationsRoot.list.length > notificationsRoot.notificationsHistoryLimit) {
        const notificationToRemove = notificationsRoot.list.pop();
        notificationsRoot.destroyNotification(notificationToRemove);
      }
      notificationsRoot.notify(notificationObject);
    }
  }

  Component {
    id: notificationObjectComponent
    NotificationObject {}
  }
  Component {
    id: notificationTimerComponent
    NotificationTimer {}
  }
}
