import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell

import "../../common"
import "../../services"
import "../widgets/common"

StyledButton {
  id: root

  property DesktopEntry entry
  buttonRadius: Style.rounding.verysmall
  clip: true

  onClicked: {
    entry.execute();
    Utils.updateRecentApps(entry.name);
    GlobalState.leftSidebar.open = false;
    GlobalState.leftSidebar.requestFocus(false);
  }

  contentItem: RowLayout {
    spacing: Style.sizes.spacingMedium
    Layout.fillWidth: true

    IconImage {
      source: Quickshell.iconPath(AppSearch.guessIcon(root.entry.icon), "image-missing")
      visible: !!this.source
      asynchronous: true
      mipmap: true

      Layout.preferredWidth: Style.sizes.iconExtraLarge
      Layout.preferredHeight: Layout.preferredWidth
      Layout.alignment: Qt.AlignVCenter
    }

    ColumnLayout {
      spacing: 0
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

      StyledText {
        Layout.fillWidth: true
        elide: Text.ElideRight

        text: root.entry.name
        font.pixelSize: Style.font.pixelSize.small
        font.weight: Font.Bold
      }

      StyledText {
        visible: !!root.entry.comment
        elide: Text.ElideRight
        Layout.fillWidth: true

        text: root.entry.comment ?? ""
        font.pixelSize: Style.font.pixelSize.smaller
        color: Style.colors.outline
      }
    }
  }
}
