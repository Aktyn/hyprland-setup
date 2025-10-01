import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications

import "../../common"
import "../../services"
import "./common"

Rectangle {
  id: root

  property Notifications.NotificationObject notificationObject
  property bool isNew: root.notificationObject.isNew
  property int padding: Style.sizes.spacingMedium

  property color backgroundColor: root.notificationObject.isNew ? Style.colors.secondaryContainer : Style.colors.surfaceVariant
  property color borderColor: root.notificationObject.isNew ? Style.colors.secondary : Style.colors.outline
  property color textColor: root.notificationObject.isNew ? Style.colors.colorOnSecondaryContainer : Style.colors.colorOnSurfaceVariant

  color: root.backgroundColor
  border.color: root.borderColor
  radius: Style.rounding.verysmall

  implicitWidth: Math.max(layout.width, parent.width)
  implicitHeight: layout.implicitHeight

  opacity: root.isNew ? 0 : 1
  scale: root.isNew ? 0.95 : 1

  Behavior on opacity {
    enabled: root.isNew
    NumberAnimation {
      duration: Style.animation.elementMove.duration
      easing.type: Style.animation.elementMove.type
    }
  }

  Behavior on scale {
    enabled: root.isNew
    NumberAnimation {
      duration: Style.animation.elementMove.duration
      easing.type: Style.animation.elementMove.type
    }
  }

  Component.onCompleted: {
    if (root.isNew) {
      opacity = 1;
      scale = 1;
    }
  }

  ColumnLayout {
    id: layout

    anchors.fill: parent

    spacing: 0

    RowLayout {
      Layout.fillWidth: true
      Layout.margins: root.padding

      ColumnLayout {
        Layout.fillWidth: true
        Layout.maximumWidth: 384

        RowLayout {
          Layout.fillWidth: true

          spacing: Style.sizes.spacingMedium

          CustomIcon {
            visible: !!root.notificationObject.icon
            source: root.notificationObject.icon
            Layout.preferredWidth: Style.sizes.iconLarge
            Layout.preferredHeight: Layout.preferredWidth
            iconFolder: ""
            // colorize: true
            color: root.textColor
          }

          StyledText {
            Layout.fillWidth: true
            clip: true

            text: root.notificationObject.summary
            font.pixelSize: Style.font.pixelSize.normal
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
            color: root.textColor
          }

          StyledText {
            Layout.alignment: Qt.AlignRight | Qt.AlignTop
            Layout.leftMargin: Style.sizes.spacingLarge

            text: Qt.formatDateTime(new Date(root.notificationObject.time), "hh:mm")
            font.pixelSize: Style.font.pixelSize.smaller
            color: root.textColor
          }
        }

        StyledText {
          visible: !!root.notificationObject.body

          Layout.fillWidth: true

          text: root.notificationObject.body
          font.pixelSize: Style.font.pixelSize.small
          wrapMode: Text.Wrap
          color: root.textColor
        }

        GridLayout {
          id: grid
          visible: root.notificationObject.isNew && !!root.notificationObject.notificationHandle?.actions?.length
          columns: 2
          columnSpacing: Style.sizes.spacingMedium
          rowSpacing: Style.sizes.spacingMedium
          uniformCellWidths: true
          Layout.fillWidth: true

          Repeater {
            model: root.notificationObject.notificationHandle?.actions || []

            delegate: ActionButton {
              required property NotificationAction modelData

              Layout.fillWidth: true

              content: modelData.text
              font.pixelSize: Style.font.pixelSize.small
              padding: Style.sizes.spacingSmall
              color: Style.colors.colorOnPrimaryContainer
              colBackground: Style.colors.primaryContainer
              colBackgroundHover: Style.colors.inversePrimary
              borderColor: Style.colors.inversePrimary
              borderWidth: 1
              buttonRadius: Style.rounding.unsharpenmore
              onClicked: {
                modelData.invoke();
              }
            }
          }
        }
      }
    }
  }
}
