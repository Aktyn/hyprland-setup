import QtQuick
import QtQuick.Layouts

import "../../../common"
import ".."
import "../../widgets/common"

ColumnLayout {
  spacing: Style.sizes.spacingLarge

  SettingsRow {
    label: "Low battery threshold"
    description: "The battery percentage at which to show a low battery warning."
    children: StyledSlider {
      from: 5
      to: 50
      value: Config.battery.low
      onValueChanged: Config.battery.low = value
      tooltipContent: `${Math.round(this.value)}%`
    }
  }

  HSeparator {}

  SettingsRow {
    label: "Critical battery threshold"
    description: "The battery percentage at which to show a critical battery warning."
    children: StyledSlider {
      from: 2
      to: 20
      value: Config.battery.critical
      onValueChanged: Config.battery.critical = value
      tooltipContent: `${Math.round(this.value)}%`
    }
  }

  HSeparator {}

  SettingsRow {
    label: "Suspend at critical battery"
    description: "Whether to automatically suspend the system when the battery is critical."
    children: StyledSwitch {
      checked: Config.battery.automaticSuspend
      onCheckedChanged: Config.battery.automaticSuspend = this.checked
    }
  }
}
