import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

import "../../common"
import "./common"

RowLayout {
  id: rowLayout
  visible: SystemTray.items.values.length > 0

  spacing: Style.sizes.spacingLarge

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
  }
}
