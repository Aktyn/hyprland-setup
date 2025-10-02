import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell.Io

import "../../../common"
import "../../../services"

import "../common"

Rectangle {
  id: root
  property var _editors: []
  readonly property real margin: 10
  // Size
  implicitWidth: Math.min(Screen.width, Math.max(header.implicitWidth, notesRow.implicitWidth) + margin * 2)
  implicitHeight: header.implicitHeight + notesContainer.implicitHeight + margin + 4

  color: Style.colors.surfaceContainerHigh
  radius: Style.rounding.small
  border.width: 1
  border.color: Style.colors.outlineVariant
  clip: true

  property bool open: GlobalState.bar.notesPanel.open

  onOpenChanged: {
    if (open) {
      GlobalState.bar.notesPanel.requestFocus();
    }
  }

  // Forward keystrokes to the editor if the root holds focus (unused in multi-note mode)
  // Keys.forwardTo: []

  ColumnLayout {
    id: columnLayout
    spacing: 6
    anchors {
      fill: parent
      leftMargin: root.margin
      rightMargin: root.margin
      topMargin: root.margin
      bottomMargin: root.margin
    }

    // Header
    RowLayout {
      id: header
      spacing: 6
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignHCenter

      MaterialSymbol {
        fill: 0
        text: "sticky_note_2"
        iconSize: Style.font.pixelSize.huge
        color: Style.colors.colorOnBackground
      }
      StyledText {
        text: "Notes"
        font.pixelSize: Style.font.pixelSize.large
        font.family: Style.font.family.title
        color: Style.colors.colorOnBackground
      }
      Item {
        Layout.fillWidth: true
      }
      // Add note button
      MaterialSymbol {
        id: addIcon
        text: "add"
        fill: 0
        iconSize: Style.font.pixelSize.huge
        color: Style.colors.colorOnBackground
        MouseArea {
          id: addArea
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Notes.addNote()
        }
      }
    }

    Item {
      height: 2
      Layout.fillWidth: true
    }

    // Notes list (horizontal)
    Flickable {
      id: notesContainer
      Layout.fillWidth: true
      implicitWidth: Math.min(notesRow.implicitWidth, Screen.width - root.margin * 2)
      implicitHeight: 480
      clip: true
      contentWidth: notesRow.implicitWidth
      contentHeight: notesRow.implicitHeight
      flickableDirection: Flickable.HorizontalFlick
      boundsBehavior: Flickable.StopAtBounds
      interactive: contentWidth > width

      Row {
        id: notesRow
        spacing: 10
        anchors.top: parent.top
        anchors.left: parent.left

        Repeater {
          id: notesRepeater
          model: Notes.notesModel
          delegate: Rectangle {
            id: noteCard
            width: 280
            height: notesContainer.implicitHeight - 20
            radius: Style.rounding.verysmall
            color: Style.colors.surfaceContainerHighest
            border.width: 1
            border.color: editor.activeFocus ? Style.colors.outline : Style.colors.outlineVariant

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 8 //TODO: use values from Style file
              spacing: 6

              RowLayout {
                Layout.fillWidth: true
                StyledText {
                  text: name //TODO: ?
                  color: Style.colors.colorOnSurfaceVariant
                  font.pixelSize: Style.font.pixelSize.normal
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
                MaterialSymbol {
                  text: "close"
                  fill: 0
                  iconSize: Style.font.pixelSize.large
                  color: Style.colors.colorOnSurface
                  MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notes.removeNote(index)
                  }
                }
              }

              Rectangle {
                height: 1
                Layout.fillWidth: true
                color: Style.colors.outlineVariant
                opacity: 0.5
              }

              ScrollView {
                id: editorScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                // Disable horizontal flicking of the outer notes container when hovering the editor
                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  acceptedButtons: Qt.NoButton
                  onEntered: notesContainer.interactive = false
                  onExited: notesContainer.interactive = notesContainer.contentWidth > notesContainer.width
                }

                StyledTextArea {
                  id: editor
                  width: editorScroll.width
                  wrapMode: TextEdit.Wrap
                  placeholderText: "Type your notes here..."
                  activeFocusOnPress: true
                  selectByMouse: true
                  cursorVisible: editor.activeFocus
                  selectionColor: Style.colors.secondaryContainer
                  color: Style.colors.colorOnSurface
                  onTextChanged: saveDebounce.restart()
                  KeyNavigation.priority: KeyNavigation.BeforeItem

                  // MouseArea {
                  //   anchors.fill: parent
                  //   onClicked: {
                  //     if (!editor.activeFocus) {
                  //       GlobalState.bar.notesPanel.requestFocus();
                  //       editor.forceActiveFocus();
                  //     }
                  //   }
                  // }
                }
              }

              Timer {
                id: saveDebounce
                interval: 400
                repeat: false
                onTriggered: noteFile.setText(editor.text)
              }
            }

            FileView {
              id: noteFile
              path: file
              onLoaded: {
                const t = noteFile.text();
                if (editor.text !== t)
                  editor.text = t;
              }
              onLoadFailed: error => {
                if (error == FileViewError.FileNotFound) {
                  editor.text = "";
                  noteFile.setText(editor.text);
                } else {
                  console.log("[NotesPopup] Error loading note file: " + error);
                }
              }
            }

            Component.onCompleted: {
              if (!root._editors)
                root._editors = [];
              root._editors.push(editor);
            }
            Component.onDestruction: {
              if (root._editors) {
                const i = root._editors.indexOf(editor);
                if (i >= 0)
                  root._editors.splice(i, 1);
              }
            }
          }
        }
      }
    }
  }

  Component.onCompleted: {
    if (typeof Notes.loadIndex === "function") {
      Notes.loadIndex();
    }
  }
}
