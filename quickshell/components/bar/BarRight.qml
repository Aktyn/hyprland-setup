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

  BarIconButton {
    id: rightSidebarButton

    toggled: false
    implicitWidth: Style.sizes.iconLarge * (Updates.hasUpdates ? 2 : 1) + Style.sizes.spacingExtraSmall * 2
    implicitHeight: Style.sizes.iconLarge + Style.sizes.spacingExtraSmall * 2
    onPressed: {
      GlobalState.rightSidebar.open = !GlobalState.rightSidebar.open;
    }

    property real iconRotation: GlobalState.rightSidebar.open ? 90 : 0
    // contentItem.rotation: iconRotation
    Behavior on iconRotation {
      animation: Style.animation.elementMove.numberAnimation.createObject(this)
    }

    contentItem: RowLayout {
      anchors.fill: parent

      spacing: Style.sizes.spacingExtraSmall

      MaterialSymbol {
        visible: Updates.hasUpdates

        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        Layout.preferredHeight: Style.sizes.iconLarge
        Layout.preferredWidth: Style.sizes.iconLarge

        text: "update"
        iconSize: Style.font.pixelSize.large
        color: Style.colors.primary
      }

      MaterialSymbol {
        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

        rotation: rightSidebarButton.iconRotation

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        Layout.preferredHeight: Style.sizes.iconLarge
        Layout.preferredWidth: Style.sizes.iconLarge

        text: "more_vert"
        iconSize: Style.font.pixelSize.large
        color: rightSidebarButton.toggled ? Style.colors.primary : Style.colors.colorOnSurface
      }
    }
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
      content: "Night light"
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
      console.info("New notification:", JSON.stringify(notificationObject.notificationHandle, null, 2));
    }

    LazyLoader {
      active: true

      BarAdjacentPanel {
        id: notificationsPanelContainer

        side: BarAdjacentPanel.Side.Right
        property bool hasFullScreen: !!Hyprland.monitorFor(this.screen).activeWorkspace?.toplevels.values.some(top => top.wayland?.fullscreen)
        detached: hasFullScreen

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

        StyledTooltip {
          content: "Screenshot region"
          side: StyledTooltip.TooltipSide.Left
        }
      }

      BarIconButton {
        iconName: "colorize"
        onClicked: Quickshell.execDetached(["hyprpicker", "-a"])

        StyledTooltip {
          content: "Pick color"
          side: StyledTooltip.TooltipSide.Left
        }
      }

      BarIconButton {
        iconName: "sticky_note_2"

        toggled: GlobalState.bar.notesPanel.open
        onClicked: {
          GlobalState.bar.notesPanel.open = !GlobalState.bar.notesPanel.open;
          GlobalState.bar.notesPanel.screen = section.screen;
        }

        StyledTooltip {
          content: "Notes"
          side: StyledTooltip.TooltipSide.Left
        }
      }

      BarIconButton {
        iconName: "pending_actions"

        toggled: GlobalState.osd.clipboardPanelOpen
        onClicked: {
          GlobalState.osd.clipboardPanelOpen = !GlobalState.osd.clipboardPanelOpen;
        }

        StyledTooltip {
          content: "Clipboard history"
          side: StyledTooltip.TooltipSide.Left
        }
      }
    }

    VSeparator {}

    VolumeWidget {}

    VSeparator {}

    StyledButton {
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
