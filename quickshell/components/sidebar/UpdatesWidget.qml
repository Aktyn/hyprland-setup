import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import "../../common"
import "../../services"

import "../widgets/common"

ColumnLayout {
  spacing: Style.sizes.spacingMedium

  Text {
    Layout.fillWidth: true

    text: Updates.isUpdating ? "Updating..." : `Updates available (${Updates.updatesCount})`
    horizontalAlignment: Text.AlignHCenter
    font.pixelSize: Style.font.pixelSize.large
    font.weight: Font.DemiBold
    color: Style.colors.primary
  }

  ActionButton {
    visible: !Updates.isUpdating

    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter

    iconName: "update"
    content: "Update now"

    onClicked: {
      Updates.update();
    }
  }

  ScrollView {
    id: scrollView
    visible: Updates.isUpdating

    Layout.preferredWidth: parent.width
    Layout.maximumHeight: 512
    clip: true

    StyledTextArea {
      id: readonlyEditor
      width: parent.width

      wrapMode: TextEdit.Wrap
      activeFocusOnPress: true
      cursorVisible: false
      readOnly: true

      text: Updates.lastUpdateOutput
      onTextChanged: {
        scrollView.ScrollBar.vertical.position = scrollView.contentHeight;
      }

      selectByMouse: true
      selectionColor: Style.colors.secondaryContainer
      color: Style.colors.colorOnSurfaceVariant
      font.pixelSize: Style.font.pixelSize.small
    }
  }
}
