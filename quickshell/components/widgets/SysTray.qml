import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

import qs.common
import "./common"

RowLayout {
  id: rowLayout

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
    font.pixelSize: Style.font.pixelSize.larger
    color: Style.colors.outline
    text: "•"
    visible: SystemTray.items.values.length > 0
  }
}
