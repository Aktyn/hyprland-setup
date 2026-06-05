import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import "."
import "./apps"
import "./options"
import "../widgets/calendar"
import "../../common"

ColumnLayout {
  id: root

  required property ShellScreen screen

  spacing: 0

  TabBar {
    id: bar
    Layout.preferredWidth: root.width

    Repeater {
      model: ["APPS", "TIME TOOLS", "OPTIONS"]

      PanelTabButton {
        id: tabButton
        required property string modelData
        text: modelData
        iconName: getIconName(modelData)
        function getIconName(name: string): string {
          switch (name) {
          case "APPS":
            return "apps";
          case "TIME TOOLS":
            return "acute";
          case "OPTIONS":
            return "dashboard";
          case "CONFIG":
            return "tune";
          }

          throw Error("Unknown panel tab: " + name);
        }
      }
    }

    background: Rectangle {
      color: Qt.lighter(Style.colors.surface, 2)
    }

    currentIndex: GlobalState.bar.mainPanel.mainPanelTabIndex
    onCurrentIndexChanged: {
      GlobalState.bar.mainPanel.mainPanelTabIndex = currentIndex;
    }
  }

  StackLayout {
    currentIndex: bar.currentIndex

    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
    Layout.fillWidth: true
    Layout.minimumWidth: 768
    Layout.maximumWidth: root.screen.width - (HyprlandInfo.general.gapsOut[1] + HyprlandInfo.general.gapsOut[3])
    Layout.preferredWidth: GlobalState.bar.mainPanel.currentContentWidth
    Layout.preferredHeight: GlobalState.bar.mainPanel.currentContentHeight

    TabContent {
      active: bar.currentIndex === 0
      sourceComponent: AppsPanel {}
    }

    TabContent {
      active: bar.currentIndex === 1
      sourceComponent: CalendarPanel {}
    }

    TabContent {
      active: bar.currentIndex === 2
      sourceComponent: OptionsPanel {}
    }
  }
}
