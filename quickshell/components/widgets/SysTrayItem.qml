pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

import qs.common

MouseArea {
  id: root

  property var bar: root.QsWindow.window
  required property SystemTrayItem item
  property bool targetMenuOpen: false
  property int trayItemSize: Style.font.pixelSize.larger

  acceptedButtons: Qt.LeftButton | Qt.RightButton
  implicitHeight: root.trayItemSize
  implicitWidth: root.trayItemSize
  onClicked: event => {
    switch (event.button) {
    case Qt.LeftButton:
      item.activate();
      break;
    case Qt.RightButton:
      if (item.hasMenu) {
        menu.open();
      }
      break;
    }
    event.accepted = true;
  }

  QsMenuAnchor {
    id: menu

    menu: root.item.menu
    anchor.window: root.bar
    anchor.rect.x: root.mapToGlobal(root.x, root.y).x
    anchor.rect.height: Config.bar.height
    anchor.edges: Edges.Bottom
  }

  IconImage {
    id: trayIcon
    visible: false
    source: root.item.icon
    anchors.centerIn: parent
    width: parent.width
    height: parent.height
  }

  Loader {
    active: true
    anchors.fill: trayIcon
    sourceComponent: Item {
      Desaturate {
        id: desaturatedIcon
        visible: true
        anchors.fill: parent
        source: trayIcon
        desaturation: Config.bar.desaturateTrayIcons
      }
    }
  }
}
