import QtQuick
import QtQuick.Layouts

import "../../common"
import "../widgets"
import "../widgets/common"

BarSection {
  stretch: true

  StyledButton {
    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
    Layout.fillWidth: false
    Layout.rightMargin: Style.sizes.spacingMedium
    property real buttonPadding: Style.sizes.spacingExtraSmall
    implicitWidth: Math.min(64, Config.bar.height - Style.sizes.spacingSmall * 2)
    implicitHeight: implicitWidth

    buttonRadius: Style.rounding.full
    toggled: false

    //TODO
    // GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
    onPressed: {
      console.log("Left icon button pressed");
    }

    CustomIcon {
      anchors.centerIn: parent
      height: parent.height - parent.buttonPadding * 2
      width: height

      source: "aktyn-logo"
      colorize: true
      color: Style.colors.colorOnSurface
    }
  }

  ActiveWindowInfo {}

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
