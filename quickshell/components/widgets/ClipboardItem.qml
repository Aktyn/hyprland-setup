import QtQuick
import QtQuick.Layouts

import "../../services"
import "../../common"

import "./common"

Item {
  id: root
  required property ClipboardEntryObject modelData
  required property int index
  property bool isFirst: this.index === 0

  width: parent?.width ?? 512
  height: layout.implicitHeight

  property real radius: Style.rounding.normal

  RowLayout {
    id: layout

    width: parent.width
    spacing: 0

    StyledButton {
      enabled: !root.isFirst
      opacity: 1

      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      implicitHeight: Style.sizes.iconExtraLarge

      buttonRadius: root.radius
      contentItem: StyledText {
        text: root.modelData.name
        elide: Text.ElideRight
        font.bold: root.isFirst
        color: root.isFirst ? Style.colors.primary : Style.colors.colorOnSurface
      }

      StyledTooltip {
        content: root.isFirst ? "Current clipboard item" : "Click to copy"
        side: StyledTooltip.TooltipSide.Bottom
      }

      downAction: () => {
        if (!root.isFirst) {
          root.modelData.copy();
        }
      }
    }

    StyledButton {
      visible: !root.isFirst

      Layout.alignment: Qt.AlignVCenter
      implicitHeight: Style.sizes.iconExtraLarge
      implicitWidth: this.implicitHeight

      buttonRadius: root.radius

      contentItem: MaterialSymbol {
        text: "delete"
        font.pixelSize: Style.sizes.iconExtraLarge * 0.618
      }

      StyledTooltip {
        content: "Remove from history"
        side: StyledTooltip.TooltipSide.Left
      }

      downAction: () => {
        root.modelData.remove();
      }
    }
  }

  component ClipboardEntryObject: QtObject {
    id: wrapper

    required property string rawString
    required property string name
    required property string type

    function copy() {
      ClipboardHistory.copy(this.rawString);
      console.info("Restored clipboard entry from the history");
    }
    function remove() {
      ClipboardHistory.deleteEntry(this.rawString);
      console.info("Removed clipboard entry from the history");
    }
  }
}
