import QtQuick
import QtQuick.Layouts

import "../../../common"
import ".."
import "../../widgets/common"

ColumnLayout {
  spacing: Style.sizes.spacingLarge

  SettingsRow {
    label: "Default timeout"
    description: "The default timeout for notifications in milliseconds."
    children: StyledSlider {
      from: 1000
      to: 20000
      value: Config.notifications.defaultTimeout
      onValueChanged: Config.notifications.defaultTimeout = value
      tooltipContent: `${Math.round(this.value)}ms`
    }
  }
}
