import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.common
import qs.services
import "../widgets/common"
import "../widgets"

ColumnLayout {
  id: root

  spacing: Style.sizes.spacingMedium

  //TODO: show linear progress indicating when the list will auto-hide; pause auto-hide/newNotificationAutoHide on mouse hover

  property int screenHeight: GlobalState.bar.notificationsPanel.screen?.height ?? 1080

  property list<Notifications.NotificationObject> newNotifications: Notifications.list.filter(n => n.isNew)
  property list<Notifications.NotificationObject> acknowledgedNotifications: Notifications.list.filter(n => !n.isNew)

  property bool isTemporaryOpen: !GlobalState.bar.notificationsPanel.open
  property bool isTemporaryOpenDelayed: isTemporaryOpen
  Timer {
    id: closeTimer
    interval: 300
    onTriggered: root.isTemporaryOpenDelayed = true
  }
  onIsTemporaryOpenChanged: {
    if (isTemporaryOpen) {
      closeTimer.start()
    } else {
      closeTimer.stop()
      root.isTemporaryOpenDelayed = false
    }
  }


  Text {
    visible: !root.newNotifications.length && !root.acknowledgedNotifications.length
    text: "No notifications"
    color: Style.colors.outline
    font.pixelSize: Style.font.pixelSize.normal
    Layout.alignment: Qt.AlignHCenter
  }

  Repeater {
    model: root.newNotifications
    delegate: NotificationItem {
      Layout.fillWidth: true
      notificationObject: modelData
    }
  }

  ActionButton {
    visible: root.newNotifications.length > 0

    iconName: "clear_all"
    content: root.newNotifications.length > 1 ? "Acknowledge all" : "Acknowledge"
    Layout.fillWidth: true
    onClicked: {
      for (const notificationObject of Notifications.list) {
        if (notificationObject.isNew) {
          notificationObject.acknowledge();
        }
      }
    }
  }

  HSeparator {
    visible: root.newNotifications.length > 0 && root.acknowledgedNotifications.length > 0 && !root.isTemporaryOpenDelayed
  }

  ScrollView {
    visible: root.acknowledgedNotifications.length > 0 && !root.isTemporaryOpenDelayed

    Layout.fillWidth: true
    Layout.maximumHeight: Math.round(root.screenHeight * 0.618)
    Layout.minimumWidth: 320
    clip: true

    ListView {
      spacing: Style.sizes.spacingMedium
      model: root.acknowledgedNotifications
      delegate: NotificationItem {
        notificationObject: modelData
        Layout.fillWidth: true
      }
    }
  }

  ActionButton {
    visible: root.acknowledgedNotifications.length > 0 && !root.isTemporaryOpenDelayed

    iconName: "delete_sweep"
    content: "Clear all notifications"
    Layout.fillWidth: true
    onClicked: {
      Notifications.clearAll();
      GlobalState.bar.notificationsPanel.open = false;
    }
  }
}
