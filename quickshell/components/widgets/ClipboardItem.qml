import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io

import "../../services"
import "../../common"

import "./common"

Item {
  id: root
  required property ClipboardEntryObject modelData
  required property int index
  property bool isFirst: this.index === 0

  property bool isFile: modelData.name.startsWith("file://")

  width: parent?.width ?? 512
  height: layout.implicitHeight

  property real radius: Style.rounding.normal

  RowLayout {
    id: layout

    width: parent.width
    spacing: 0

    StyledButton {
      id: button

      enabled: !root.isFirst
      opacity: 1

      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
      Layout.preferredHeight: Style.sizes.iconExtraLarge

      buttonRadius: root.radius
      contentItem: Item {
        anchors.centerIn: parent

        //Show only name for non-file entries
        RowLayout {
          id: nonFileLayout

          anchors.fill: parent
          spacing: Style.sizes.spacingMedium

          readonly property bool isColor: root.modelData.name.match(/^["'`]?#([\dABCDEF]{3,4}|[\dABCDEF]{6}|[\dABCDEF]{8})["'`]?$/i)

          StyledText {
            visible: !root.isFile
            Layout.fillHeight: true
            Layout.fillWidth: !nonFileLayout.isColor

            text: root.modelData.name
            elide: Text.ElideRight
            font.bold: root.isFirst
            color: root.isFirst ? Style.colors.primary : Style.colors.colorOnSurface
          }

          Rectangle {
            visible: nonFileLayout.isColor
            color: root.modelData.name.replace(/[^#\dABCDEF]/gi, "")
            Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            Layout.fillHeight: true
            Layout.fillWidth: true
            radius: root.radius
          }
        }

        //File or directory entry
        ColumnLayout {
          id: fileLayout

          visible: root.isFile
          anchors.fill: parent
          spacing: Style.sizes.spacingSmall

          readonly property string absolutePath: root.isFile ? unescape(Utils.trimFileProtocol(root.modelData.name)) : ""
          property string decodedPath: ""
          property string mimeType: ""
          property bool notFound: false

          Process {
            id: filePathDecoder
            running: root.isFile
            command: ["bash", "-c", `echo '${Utils.shellSingleQuoteEscape(root.modelData.rawString)}' | cliphist decode`]
            stdout: StdioCollector {
              onStreamFinished: {
                if (this.text) {
                  fileLayout.decodedPath = this.text.trim();
                }
              }
            }
          }

          Process {
            id: checkMimetype
            command: ["xdg-mime", "query", "filetype", unescape(Utils.trimFileProtocol(fileLayout.decodedPath))]
            running: !!fileLayout.decodedPath

            stdout: StdioCollector {
              onStreamFinished: {
                if (this.text) {
                  fileLayout.mimeType = this.text;

                  if (fileLayout.mimeType.startsWith("image/")) {
                    button.Layout.preferredHeight = Style.sizes.iconExtraLarge + Math.round(layout.width * 0.618);
                  }
                }
              }
            }
            onExited: exitCode => {
              fileLayout.notFound = exitCode !== 0;
            }
          }

          RowLayout {
            Layout.topMargin: 0

            property color colorBase: fileLayout.notFound ? Style.colors.outline : (root.isFirst ? Style.colors.primary : Style.colors.colorOnSurface)

            MimeTypeIcon {
              Layout.alignment: Qt.AlignVCenter
              Layout.fillHeight: true

              mimeType: fileLayout.notFound ? null : fileLayout.mimeType
              font.pixelSize: Style.sizes.iconExtraLarge * 0.618
              color: parent.colorBase
            }

            StyledText {
              Layout.alignment: Qt.AlignVCenter
              Layout.fillWidth: true
              Layout.fillHeight: true
              // text: unescape(fileLayout.decodedPath.replace(/.*\/([^/]+)$/i, "$1"))
              text: unescape(Utils.trimFileProtocol(fileLayout.decodedPath))
              elide: Text.ElideLeft
              font.bold: root.isFirst
              color: parent.colorBase
            }
          }

          Image {
            id: imageThumbnail
            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: fileLayout.mimeType.startsWith("image/")
            source: this.visible ? fileLayout.decodedPath : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            antialiasing: true

            Layout.preferredWidth: this.implicitWidth
            Layout.preferredHeight: this.implicitHeight
            Layout.bottomMargin: Style.sizes.spacingExtraSmall

            layer.enabled: true
            layer.effect: OpacityMask {
              maskSource: Rectangle {
                width: imageThumbnail.width
                height: imageThumbnail.height
                radius: root.radius
              }
            }
          }
        }
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
