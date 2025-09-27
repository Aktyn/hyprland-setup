import QtQuick

import "../../services"
import "../../common"

Text {
  color: Style.colors.colorOnBackground
  text: Time.time
  horizontalAlignment: Text.AlignHCenter
  verticalAlignment: Text.AlignVCenter
}
