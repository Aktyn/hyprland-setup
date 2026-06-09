import QtQuick
import QtQuick.Layouts
import Quickshell

import "."
import "../../widgets/common"
import "../../../common"
import "../../../services"

ColumnLayout {
  id: root

  spacing: Style.sizes.spacingLarge

  StyledButton {
    visible: !Config.general.hideAuthorLink
    Layout.fillWidth: true

    background.implicitHeight: Style.sizes.heightExtraLarge

    contentItem: Item {
      anchors.fill: parent

      RowLayout {
        anchors.centerIn: parent

        spacing: Style.sizes.spacingMedium

        CustomIcon {
          id: aktynLogoIcon

          implicitWidth: Style.sizes.iconMedium
          implicitHeight: this.implicitWidth

          source: "aktyn-logo"
          colorize: true
          color: Style.colors.colorOnSurface
        }

        Text {
          text: "More about author"
          color: Style.colors.colorOnSurface
          font.weight: Font.Medium
          font.pixelSize: Style.font.pixelSize.small
        }
      }
    }

    onClicked: {
      Quickshell.execDetached(["xdg-open", "https://github.com/Aktyn"]);
      GlobalState.bar.mainPanel.open = false;
      GlobalState.bar.mainPanel.requestFocus?.(false);
    }
  }

  HSeparator {
    visible: !Config.general.hideAuthorLink
  }

  UpdatesWidget {
    visible: Updates.hasUpdates
    Layout.fillWidth: true
  }

  LabeledHSeparator {
    visible: Updates.hasUpdates || Updates.commitOutdated
    Layout.alignment: Qt.AlignHCenter

    columnSpacing: Updates.commitOutdated ? Style.sizes.spacingLarge : 0
    text: Updates.commitOutdated ? "New shell version available!" : ""
    color: Updates.commitOutdated ? Style.colors.primary : Style.colors.outline
  }

  ConfigPanel {
    Layout.fillWidth: true
  }

  HSeparator {}

  SessionPanel {
    Layout.fillWidth: true
  }
}

