import QtQuick
import QtQuick.Layouts

import "../../common"
import "../widgets"
import "../widgets/common"
import "../widgets/workspaces"

BarSection {
  stretch: true

  //TODO: use "apps" icon instead and move aktyn logo to right sidebar
  BarIconButton {
    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

    toggled: GlobalState.leftSidebar.open

    onPressed: {
      GlobalState.leftSidebar.open = !GlobalState.leftSidebar.open;
    }

    CustomIcon {
      id: aktynLogoIcon

      anchors.centerIn: parent
      width: Style.sizes.iconMedium
      height: this.width

      source: "aktyn-logo"
      colorize: true
      color: Style.colors.colorOnSurface
    }
  }

  ActiveWindowInfo {
    Layout.alignment: Qt.AlignVCenter
  }

  WorkspacesWidget {
    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.leftMargin: Style.sizes.spacingMedium
    Layout.alignment: Qt.AlignRight
  }
}
