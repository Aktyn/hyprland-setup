import QtQuick
import QtQuick.Layouts

import "../../../common"
import "../../../services"

Rectangle {
  id: root

  color: Colors.transparentize(Style.colors.colorOnSurface, 0.1)
  border.color: Style.colors.outline

  property string placeholder: "Search..."
  property int horizontalPadding: Style.sizes.spacingMedium
  property alias searchText: searchInput.text

  property var onNonEnterInput
  property var onEnter

  implicitHeight: searchInput.implicitHeight
  implicitWidth: searchInput.implicitWidth + horizontalPadding * 2
  radius: Style.rounding.full

  function focusInput() {
    searchInput.forceActiveFocus();
  }

  function clear() {
    searchInput.clear();
  }

  RowLayout {
    spacing: 0

    anchors.fill: parent
    anchors.leftMargin: root.horizontalPadding
    anchors.rightMargin: root.horizontalPadding

    MaterialSymbol {
      text: "search"
      iconSize: Style.font.pixelSize.larger
      horizontalAlignment: Text.AlignLeft
      color: Style.colors.colorOnSurfaceVariant
    }

    StyledTextArea {
      id: searchInput

      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.alignment: Qt.AlignVCenter

      activeFocusOnPress: true
      selectByMouse: true
      persistentSelection: true
      wrapMode: TextEdit.NoWrap

      color: Style.colors.colorOnSurface
      font.pixelSize: Style.font.pixelSize.large
      verticalAlignment: Text.AlignVCenter

      text: ""
      placeholderText: root.placeholder

      onTextChanged: {
        if (this.text.includes("\n")) {
          this.text = this.text.replace(/\n/, "");
          this.select(this.text.length, this.text.length);

          if (root.onEnter && typeof root.onEnter === 'function') {
            root.onEnter();
          }
        } else if (root.onNonEnterInput && typeof root.onNonEnterInput === 'function') {
          root.onNonEnterInput();
        }
      }
    }
  }
}
