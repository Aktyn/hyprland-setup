import QtQuick
import QtQuick.Layouts

import "../../../common"
import ".."
import "../../widgets/common"

ColumnLayout {
  spacing: Style.sizes.spacingLarge

  SettingsRow {
    label: "Hide author link"
    description: "Hide the link to the author's website in the sidebar."
    children: StyledSwitch {
      checked: Config.general.hideAuthorLink
      onCheckedChanged: Config.general.hideAuthorLink = checked
    }
  }

  HSeparator {}

  SettingsRow {
    label: "Panels transparency"
    description: "Transparency of the bar and panels. Requires shell restart if changed from disabled (1) to enabled (< 1)."
    children: StyledSlider {
      from: 0
      to: 1
      value: Config.general.panelsTransparency
      onValueChanged: Config.general.panelsTransparency = value
    }
  }
}
