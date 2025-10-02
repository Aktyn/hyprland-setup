import QtQuick
import QtQuick.Layouts

import "../../common"
import "../widgets"
import "../widgets/common"

BarSection {
  stretch: true

  BarIconButton {
    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
    // Layout.rightMargin: Style.sizes.spacingMedium
    // property real buttonPadding: Style.sizes.spacingExtraSmall
    // implicitWidth: Math.min(64, Config.bar.height - Style.sizes.spacingSmall * 2)
    // implicitHeight: implicitWidth
    // implicitWidth: aktynLogoIcon.width + Style.sizes.spacingExtraSmall * 2
    // implicitWidth: aktynLogoIcon.width + Style.sizes.spacingExtraSmall * 2
    // implicitHeight: this.implicitWidth

    // buttonRadius: Style.rounding.full
    toggled: false

    //TODO
    // GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
    onPressed: {
      console.log("Left icon button pressed");
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

  // Space separator
  Item {
    Layout.fillWidth: true
  }

  Text {
    Layout.alignment: Qt.AlignRight
    text: "LEFT"
    color: "#fff"
  }
}
