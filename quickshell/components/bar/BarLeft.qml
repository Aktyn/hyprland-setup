import QtQuick
import QtQuick.Layouts

import "../../common"
import "../widgets"
import "../widgets/workspaces"

BarSection {
  stretch: true

  Layout.leftMargin: Style.sizes.spacingSmall

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
