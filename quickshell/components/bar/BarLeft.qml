import QtQuick
import QtQuick.Layouts

import "../../common"
import "../widgets"
import "../widgets/workspaces"

BarSection {
  stretch: true

  BarIconButton {
    Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

    toggled: GlobalState.leftSidebar.open
    iconName: "browse"

    onPressed: {
      GlobalState.leftSidebar.open = !GlobalState.leftSidebar.open;
    }

    property real iconRotation: GlobalState.leftSidebar.open ? 90 : 0
    contentItem.rotation: iconRotation
    Behavior on iconRotation {
      animation: Style.animation.elementMove.numberAnimation.createObject(this)
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
