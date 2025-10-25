import QtQuick
import QtQuick.Layouts

import "../../../common"
import ".."
import "../../widgets/common"

ColumnLayout {
  spacing: Style.sizes.spacingLarge

  SettingsRow {
    label: "Bar height"
    description: "The height of the bar in pixels."
    children: StyledSlider {
      from: 24
      to: 72
      stepSize: 1
      value: Config.bar.height
      onValueChanged: Config.bar.height = value
      tooltipContent: `${this.value}px`
    }
  }

  HSeparator {}

  SettingsRow {
    label: "Shadow opacity"
    description: "The opacity of the shadow under the bar."
    children: StyledSlider {
      from: 0
      to: 1
      value: Config.bar.shadowOpacity
      onValueChanged: Config.bar.shadowOpacity = value
    }
  }

  HSeparator {}

  SettingsRow {
    label: "Desaturate tray icons"
    description: "The amount to desaturate the tray icons. 1.0 means fully grayscale."
    children: StyledSlider {
      from: 0
      to: 1
      value: Config.bar.desaturateTrayIcons
      onValueChanged: Config.bar.desaturateTrayIcons = value
    }
  }

  HSeparator {}

  SettingsRow {
    label: "Panel slide duration"
    description: "The duration of the panel slide animation in milliseconds."
    children: StyledSlider {
      from: 100
      to: 1000
      stepSize: 1
      value: Config.bar.panelSlideDuration
      onValueChanged: Config.bar.panelSlideDuration = value
      tooltipContent: `${this.value}ms`
    }
  }
}
