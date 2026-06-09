import QtQuick
import QtQuick.Layouts

import "../../widgets/common"
import "../../../common"
import "../../../services"

ColumnLayout {
  spacing: Style.sizes.spacingMedium
  Layout.fillWidth: true
  Layout.alignment: Qt.AlignHCenter

  GridLayout {
    id: updatesRow

    columns: Updates.isUpdating ? 1 : 2
    columnSpacing: Style.sizes.spacingMedium
    uniformCellWidths: true

    Text {
      text: Updates.isUpdating ? "Updating..." : `Updates available (${Updates.updatesCount}):`
      Layout.fillWidth: true
      horizontalAlignment: Updates.isUpdating ? Text.AlignHCenter : Text.AlignRight
      font.pixelSize: Style.font.pixelSize.large
      font.weight: Font.DemiBold
      color: Style.colors.primary
    }

    ActionButton {
      visible: !Updates.isUpdating

      Layout.alignment: Qt.AlignHCenter

      iconName: "system_update_alt"
      content: "Update system packages"

      onClicked: {
        Updates.update();
      }
    }
  }
}
