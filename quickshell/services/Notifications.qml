pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
  id: notificationsRoot

  component NotificationObject: QtObject {
    id: wrapper

    required property Notification notification

    property bool isNew: true
    property double time: 0
    property int timeout: 5000

    property Timer timer

    function acknowledge() {
      wrapper.isNew = false;
    }
  }
  component NotificationTimer: Timer {
    required property NotificationObject notificationObject

    interval: 5000
    running: true
    onTriggered: function () {
      this.notificationObject.acknowledge();
      this.destroy();
    }
  }

  property int notificationsHistoryLimit: 64
  property list<NotificationObject> list: []
  property bool hasUnread: list.some(n => n.isNew)

  function destroyNotification(notificationObject: NotificationObject) {
    notificationObject.timer?.stop();
    notificationObject.notification.dismiss();
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

      const expireTimeout = notification.expireTimeout <= 0 ? 5000 : notification.expireTimeout;
      const realTimeout = notification.urgency === NotificationUrgency.Critical ? ~(1 << 31) : expireTimeout;

      const notificationObject = notificationObjectComponent.createObject(notificationsRoot, {
        notification: notification,
        time: Date.now(),
        timeout: realTimeout
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
