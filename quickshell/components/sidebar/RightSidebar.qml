import QtQuick
import QtQuick.Layouts
import Quickshell

import "../../common"
import "../../services"

import "../widgets/common"
import "."

ColumnLayout {
  id: root

  spacing: Style.sizes.spacingLarge

  StyledButton {
    visible: !Config.general.hideAuthorLink
    Layout.fillWidth: true

    contentItem: Item {
      anchors.fill: parent

      RowLayout {
        anchors.centerIn: parent

        spacing: Style.sizes.spacingLarge

        CustomIcon {
          id: aktynLogoIcon

          implicitWidth: Style.sizes.iconExtraLarge
          implicitHeight: this.implicitWidth

          source: "aktyn-logo"
          colorize: true
          color: Style.colors.colorOnSurface
        }

        Text {
          text: "Aktyn"
          color: Style.colors.colorOnSurface
          font.weight: Font.Medium
          font.pixelSize: Style.font.pixelSize.huge
        }
      }
    }

    onClicked: {
      Quickshell.execDetached(["xdg-open", "https://github.com/Aktyn"]);
      GlobalState.rightSidebar.open = false;
      GlobalState.rightSidebar.requestFocus?.(false);
    }
  }

  HSeparator {
    visible: !Config.general.hideAuthorLink
  }

  UpdatesWidget {
    visible: Updates.hasUpdates
    Layout.fillWidth: true
  }

  HSeparator {
    visible: Updates.hasUpdates
  }

  ConfigPanel {
    Layout.fillWidth: true
  }

  HSeparator {}

  SessionPanel {
    Layout.fillWidth: true
  }
}
