import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications

import "../../common"
import "../../services"
import "."
import "../widgets"
import "../widgets/common"
import "../widgets/audio"

BarSection {
  id: section
  required property ShellScreen screen

  mirror: true
  stretch: true

  //TODO: right sidebar toggle
  BarIconButton {
    toggled: false
    iconName: "menu"
    color: Style.colors.outlineVariant //TODO: remove
    onClicked:
    //TODO: open right sidebar
    {}
  }

  BarIconButton {
    id: nightLightButton
    property bool enabled: Hyprsunset.active
    toggled: enabled
    iconName: "bedtime"
    onClicked: {
      Hyprsunset.toggle();
    }

    Component.onCompleted: {
      Hyprsunset.fetchState();
    }

    StyledTooltip {
      content: "Night Light"
      side: StyledTooltip.TooltipSide.Left
    }
  }

  BluetoothToggle {}

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

  RowLayout {
    spacing: Style.sizes.spacingLarge
    Layout.alignment: Qt.AlignVCenter
    Layout.fillHeight: false

    Resources {}

    VSeparator {}

    RowLayout {
      spacing: Style.sizes.spacingSmall

      BarIconButton {
        iconName: "screenshot_region"
        onClicked: Quickshell.execDetached("hyprshot --freeze --clipboard-only --mode region --silent".split(" "))
      }

      BarIconButton {
        iconName: "colorize"
        onClicked: Quickshell.execDetached(["hyprpicker", "-a"])
      }

      BarIconButton {
        iconName: "sticky_note_2"

        toggled: GlobalState.bar.notesPanel.open

        onClicked: {
          GlobalState.bar.notesPanel.open = !GlobalState.bar.notesPanel.open;
          GlobalState.bar.notesPanel.screen = section.screen;
        }
      }
    }

    VSeparator {}

    VolumeWidget {}

    VSeparator {}

    StyledButton {
      id: clockWidgetButton

      Layout.alignment: Qt.AlignVCenter
      implicitWidth: mediaWidget.width
      implicitHeight: mediaWidget.height

      toggled: GlobalState.bar.mediaControls.open
      padding: 0
      buttonRadius: Style.rounding.full

      MediaWidget {
        id: mediaWidget
        Layout.alignment: Qt.AlignVCenter
      }

      onPressed: {
        GlobalState.bar.mediaControls.open = !GlobalState.bar.mediaControls.open;
        GlobalState.bar.mediaControls.screen = section.screen;
      }
      altAction: () => {
        mediaWidget.activePlayer.next();
      }
      middleClickAction: () => {
        mediaWidget.activePlayer.togglePlaying();
      }
    }
  }
}
