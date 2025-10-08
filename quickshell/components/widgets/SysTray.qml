import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

import "../../common"
import "./common"

RowLayout {
  id: rowLayout
  visible: SystemTray.items.values.length > 0

  spacing: Style.sizes.spacingMedium

  Repeater {
    model: SystemTray.items

    SysTrayItem {
      required property SystemTrayItem modelData
      item: modelData
    }
  }

  StyledText {
    Layout.alignment: Qt.AlignVCenter
    Layout.leftMargin: Style.sizes.spacingSmall
    font.pixelSize: Style.font.pixelSize.larger
    color: Style.colors.outline
    text: "•"
  }
}
