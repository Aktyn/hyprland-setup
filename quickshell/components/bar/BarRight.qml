import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

import "../widgets"
import "../widgets/common"
import "../../common"
import "../../services"

BarSection {
  id: section
  required property ShellScreen screen

  height: parent.height

  mirror: true
  stretch: true

  Text {
    text: "TODO: settings panel"
    color: "#fff"
  }

  StyledButton {
    id: notificationsButton

    Layout.alignment: Qt.AlignVCenter
    property int buttonPadding: Style.sizes.spacingSmall
    implicitWidth: Math.min(64, Config.bar.height - Style.sizes.spacingSmall * 2)
    implicitHeight: implicitWidth

    buttonRadius: Style.rounding.full
    toggled: false

    onPressed: {
      GlobalState.bar.notificationsPanel.open = !GlobalState.bar.notificationsPanel.open;
      GlobalState.bar.notificationsPanel.screen = section.screen;

      if (!GlobalState.bar.notificationsPanel.open) {
        GlobalState.bar.notificationsPanel.newNotificationAutoHide.running = false;
      }
    }

    CustomIcon {
      anchors.centerIn: parent
      height: parent.height - parent.buttonPadding * 2
      width: height

      source: "bell-badge"
      colorize: true
      color: Style.colors.outline //TODO: Style.colors.primary if there are unread notifications
    }

    Component.onCompleted: {
      Notifications.onNotify.connect(showNewNotification);
    }

    function showNewNotification(notification) {
      console.log("New notification:", JSON.stringify({
        "notificationId": notification.notificationId,
        "actions": notification.actions,
        "appIcon": notification.appIcon,
        "appName": notification.appName,
        "body": notification.body,
        "image": notification.image,
        "summary": notification.summary,
        "time": notification.time,
        "timeout": notification.timeout,
        "urgency": notification.urgency,
        "new": notification.new //TODO: use to filter out new notifications to show in the temporary list
      }, null, 2));

      const interval = notification.urgency === NotificationUrgency.Critical ? ~(1 << 29) : notification.timeout;

      if (!GlobalState.bar.notificationsPanel.open) {
        GlobalState.bar.notificationsPanel.open = true;

        //TODO: auto hide after notification.timeout
        GlobalState.bar.notificationsPanel.newNotificationAutoHide.interval = interval;
        GlobalState.bar.notificationsPanel.newNotificationAutoHide.running = true;
      } else {
        GlobalState.bar.notificationsPanel.newNotificationAutoHide.interval += interval;
      }
    }

    LazyLoader {
      active: true

      BarAdjacentPanel {
        id: notificationsPanelContainer

        side: BarAdjacentPanel.Side.Right

        screen: GlobalState.bar.notificationsPanel.screen
        show: GlobalState.bar.notificationsPanel.open

        closeOnBackgroundClick: !GlobalState.bar.notificationsPanel.newNotificationAutoHide.running
        onBackgroundClick: function () {
          GlobalState.bar.notificationsPanel.open = false;
        }

        Component.onCompleted: {
          GlobalState.bar.notificationsPanel.requestFocus = notificationsPanelContainer.onRequestFocus;
        }

        Text {
          //TODO: show linear progress indicating when the list will auto-hide; pause auto-hide/newNotificationAutoHide on mouse hover
          text: "TODO: shortly open to show new notification"
          color: "#f55"
        }
      }
    }
  }

  SysTray {}

  NetworkBandwidth {}

  // Space separator
  Item {
    Layout.fillWidth: true
  }

  Text {
    text: "RIGHT"
    color: "#fff"
  }
}
