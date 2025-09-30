pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

import "../common"

Singleton {
  id: notificationsRoot

  signal notify(notification: Notification)

  //NOTE: make sure there is no notification service running (e.g.: swaync) that blocks org.freedesktop.Notifications dbus
  NotificationServer {
    // id: notifServer
    // actionIconsSupported: true
    // actionsSupported: true
    // bodyHyperlinksSupported: true
    // bodyImagesSupported: true
    // bodyMarkupSupported: true
    // bodySupported: true
    // imageSupported: true
    // keepOnReload: false
    // persistenceSupported: true

    onNotification: notification => {
      // console.log("NOTIFICATION", notification.id, notification.summary, notification.body);
      notification.tracked = true;
      notification.timeout = notification.expireTimeout < 0 ? 5000 : notification.expireTimeout;
      notification.new = true;
      // const newNotifObject = notifComponent.createObject(root, {
      //   "notificationId": notification.id + root.idOffset,
      //   "notification": notification,
      //   "time": Date.now()
      // });
      // root.list = [...root.list, newNotifObject];

      // // Popup
      // if (!root.popupInhibited) {
      //   newNotifObject.popup = true;
      //   if (notification.expireTimeout != 0) {
      //     newNotifObject.timer = notifTimerComponent.createObject(root, {
      //       "notificationId": newNotifObject.notificationId,
      //       "interval": notification.expireTimeout < 0 ? 5000 : notification.expireTimeout
      //     });
      //   }
      // }

      // root.notify(newNotifObject);
      notificationsRoot.notify(notification);
    // // console.log(notifToString(newNotifObject));
    // notifFileView.setText(stringifyList(root.list));
    }
  }
}
