import QtQuick
import QtQuick.Layouts

import "../../../common"
import "../../../services"

Rectangle {
  Layout.fillHeight: true
  Layout.maximumHeight: Style.sizes.heightLarge
  implicitWidth: 1
  color: Colors.transparentize(Style.colors.outline, 0.25)
}
