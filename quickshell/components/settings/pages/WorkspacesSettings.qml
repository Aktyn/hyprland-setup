import QtQuick
import QtQuick.Layouts

import "../../../common"
import ".."
import "../../widgets/common"

ColumnLayout {
  spacing: Style.sizes.spacingLarge

  SettingsRow {
    label: "Number of workspaces"
    description: "The number of workspaces to display."
    children: StyledSlider {
      from: 1
      to: 10
      value: Config.workspaces.count
      stepSize: 1
      onValueChanged: Config.workspaces.count = value
      tooltipContent: this.value
    }
  }
}
