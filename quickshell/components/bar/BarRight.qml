import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

import "../../common"
import "../../services"
import "."
import "../widgets"
import "../widgets/common"

BarSection {
  id: section
  required property ShellScreen screen

  height: parent.height

  mirror: true
  stretch: true

  Text {
    Layout.alignment: Qt.AlignRight
    text: "TODO: status icons and right sidebar toggle"
    color: Style.colors.outlineVariant
    font.pixelSize: Style.font.pixelSize.smaller
  }

  StyledButton {
    id: notificationsButton

    visible: Notifications.list.length > 0

    Layout.alignment: Qt.AlignVCenter
    property int buttonPadding: Style.sizes.spacingSmall
    implicitWidth: Math.min(64, Config.bar.height - Style.sizes.spacingSmall * 2)
    implicitHeight: implicitWidth

    buttonRadius: Style.rounding.full
    toggled: false

    onPressed: {
      const open = !GlobalState.bar.notificationsPanel.open;
      GlobalState.bar.notificationsPanel.screen = section.screen;

      for (const notificationObject of Notifications.list) {
        if (notificationObject.isNew && notificationObject.urgency === NotificationUrgency.Critical) {
          notificationObject.acknowledge();
          open = false;
        }
      }

      GlobalState.bar.notificationsPanel.open = open;
    }

    CustomIcon {
      anchors.centerIn: parent
      height: parent.height - parent.buttonPadding * 2
      width: height

      source: Notifications.hasUnread ? "bell-badge" : "bell"
      colorize: true
      color: Notifications.hasUnread ? Style.colors.primary : Style.colors.outline
    }

    Component.onCompleted: {
      Notifications.onNotify.connect(showNewNotification);
    }

    function showNewNotification(notificationObject: Notifications.NotificationObject) {
      console.log("New notification:", JSON.stringify(notificationObject.notificationHandle, null, 2));
    }

    LazyLoader {
      active: true

      BarAdjacentPanel {
        id: notificationsPanelContainer

        side: BarAdjacentPanel.Side.Right

        screen: GlobalState.bar.notificationsPanel.screen
        show: GlobalState.bar.notificationsPanel.open && Notifications.list.length > 0 || notificationsPanel.newNotifications.length > 0

        closeOnBackgroundClick: GlobalState.bar.notificationsPanel.open
        onBackgroundClick: function () {
          GlobalState.bar.notificationsPanel.open = false;
        }

        Component.onCompleted: {
          GlobalState.bar.notificationsPanel.requestFocus = notificationsPanelContainer.onRequestFocus;
        }

        NotificationsPanel {
          id: notificationsPanel
          Layout.minimumWidth: 320
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

  BarIconButton {
    iconName: "sticky_note_2"

    toggled: GlobalState.bar.notesPanel.open

    onPressed: {
      GlobalState.bar.notesPanel.open = !GlobalState.bar.notesPanel.open;
      GlobalState.bar.notesPanel.screen = section.screen;
    }
  }
}
