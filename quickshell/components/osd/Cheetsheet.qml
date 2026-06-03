pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

import "../../common"
import "../../services"
import "../widgets/common"

import "../../scripts/levendist.js" as Levendist

Scope {
  id: root
  property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
  property var bindsModel: []

  function parseBinds(jsonStr) {
    const catRules = {
      "Windows": ["window", "split", "floating", "pin", "fullscreen"],
      "Launchers": ["launch", "menu", "cheetsheet", "picker", "snip", "screenshot", "ocr", "clipboard"],
      "System & Media": ["volume", "mute", "mic", "brightness", "shutdown", "reboot", "suspend", "lock", "logout", "shell", "play/pause", "track"],
      "Workspaces": ["workspace", "monitor"]
    };

    function getCategory(desc) {
      let d = desc.toLowerCase();
      for (let cat in catRules) {
        if (catRules[cat].some(keyword => d.includes(keyword))) {
          return cat;
        }
      }
      return "Miscellaneous";
    }

    const keyMap = {
      "SUPER_L": "SUPER",
      "SUPER_R": "SUPER",
      "SHIFT_L": "SHIFT",
      "SHIFT_R": "SHIFT",
      "CTRL_L": "CTRL",
      "CTRL_R": "CTRL",
      "ALT_L": "ALT",
      "ALT_R": "ALT"
    };

    function formatKey(modmask, keyName) {
      let mods = [];
      if (modmask & 64)
        mods.push("SUPER");
      if (modmask & 4)
        mods.push("CTRL");
      if (modmask & 8)
        mods.push("ALT");
      if (modmask & 1)
        mods.push("SHIFT");

      let k = keyMap[keyName] || keyName;
      if (mods.includes(k)) {
        return mods;
      }
      mods.push(k);
      return mods;
    }

    let data = [];
    try {
      data = JSON.parse(jsonStr);
    } catch (e) {
      return;
    }

    const validBinds = data.filter(b => !b.mouse && b.has_description && b.description !== "");

    let groups = {};
    validBinds.forEach(b => {
      const keys = formatKey(b.modmask, b.key);
      const cat = getCategory(b.description);
      const desc = b.description;

      if (!groups[cat])
        groups[cat] = {};
      if (!groups[cat][desc])
        groups[cat][desc] = [];

      groups[cat][desc].push(keys);
    });

    let model = [];
    for (let cat in groups) {
      let items = [];
      for (let desc in groups[cat]) {
        items.push({
          description: desc,
          shortcuts: groups[cat][desc]
        });
      }
      items.sort((a, b) => a.description.localeCompare(b.description) * 0.05 + Levendist.computeScore(a.description, b.description));
      model.push({
        category: cat,
        items: items
      });
    }

    // const catOrder = ["Workspaces", "Launchers", "System & Media", "Miscellaneous", "Windows"];
    // model.sort((a, b) => {
    //   let iA = catOrder.indexOf(a.category);
    //   let iB = catOrder.indexOf(b.category);
    //   if (iA === -1)
    //     iA = 999;
    //   if (iB === -1)
    //     iB = 999;
    //   return iA - iB;
    // });
    model.sort((a, b) => b.items.length - a.items.length);

    root.bindsModel = model;
  }

  Loader {
    active: GlobalState.osd.cheetsheetOpen

    sourceComponent: PanelWindow {
      id: osdRoot

      Connections {
        target: root
        function onFocusedScreenChanged() {
          osdRoot.screen = root.focusedScreen;
        }
      }

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      exclusionMode: ExclusionMode.Normal
      color: "transparent"

      MouseArea {
        anchors.fill: parent
        onClicked: {
          GlobalState.osd.cheetsheetOpen = false;
        }
      }

      Process {
        id: bindsProcess
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
          onStreamFinished: {
            root.parseBinds(this.text);
          }
        }
      }

      Component.onCompleted: {
        bindsProcess.running = true;
        if (this.WlrLayershell && GlobalState.transparencyEnabled) {
          this.WlrLayershell.namespace = "quickshell:panel";
          this.WlrLayershell.layer = WlrLayer.Top;
        }
      }

      visible: GlobalState.osd.cheetsheetOpen

      ColumnLayout {
        id: columnLayout
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.sizes.spacingMedium
        anchors.horizontalCenter: parent.horizontalCenter

        Rectangle {
          Layout.maximumHeight: root.focusedScreen ? root.focusedScreen.height * 0.8 : 800
          Layout.maximumWidth: root.focusedScreen ? root.focusedScreen.width * 0.8 : 1200
          Layout.minimumWidth: root.focusedScreen ? root.focusedScreen.width * 0.866 : 876

          implicitHeight: layout.implicitHeight + Style.sizes.spacingExtraLarge * 2
          implicitWidth: layout.implicitWidth + Style.sizes.spacingExtraLarge * 2

          clip: true

          color: GlobalState.backgroundColor
          border.color: Style.colors.outlineVariant
          radius: Style.rounding.large

          ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: Style.sizes.spacingExtraLarge
            spacing: Style.sizes.spacingLarge

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: "Cheatsheet"
              color: Style.colors.colorOnSurface
              font.weight: Font.DemiBold
              font.pixelSize: Style.font.pixelSize.huge
              font.family: Style.font.family.title
            }

            ScrollView {
              Layout.fillWidth: true
              Layout.fillHeight: true
              contentWidth: availableWidth
              clip: true

              ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

              Flow {
                width: parent.width
                spacing: Style.sizes.spacingLarge

                Repeater {
                  model: root.bindsModel

                  delegate: Rectangle {
                    id: categoryDelegate
                    required property string category
                    required property var items

                    width: 384
                    implicitHeight: categoryLayout.implicitHeight + Style.sizes.spacingLarge * 2
                    color: Style.colors.surfaceContainer
                    border.color: Style.colors.outlineVariant
                    radius: Style.rounding.normal

                    ColumnLayout {
                      id: categoryLayout
                      anchors.fill: parent
                      anchors.margins: Style.sizes.spacingLarge
                      spacing: Style.sizes.spacingLarge

                      Text {
                        text: categoryDelegate.category
                        color: Style.colors.primary
                        font.weight: Font.DemiBold
                        font.pixelSize: Style.font.pixelSize.large
                        font.family: Style.font.family.title
                        Layout.bottomMargin: Style.sizes.spacingSmall
                      }

                      Repeater {
                        model: categoryDelegate.items
                        delegate: RowLayout {
                          id: itemDelegate
                          required property string description
                          required property var shortcuts

                          Layout.fillWidth: true

                          Text {
                            text: itemDelegate.description
                            color: Style.colors.colorOnSurface
                            font.pixelSize: Style.font.pixelSize.small
                            Layout.fillWidth: true
                            wrapMode: Text.Wrap
                          }

                          ColumnLayout {
                            spacing: Style.sizes.spacingSmall
                            Repeater {
                              model: itemDelegate.shortcuts
                              delegate: RowLayout {
                                id: shortcutDelegate
                                required property var modelData

                                spacing: Style.sizes.spacingExtraSmall
                                Repeater {
                                  model: shortcutDelegate.modelData
                                  delegate: Rectangle {
                                    id: keyDelegate
                                    required property string modelData

                                    color: Style.colors.primaryContainer
                                    radius: Style.rounding.small
                                    border.color: Style.colors.colorOnPrimaryContainer
                                    border.width: 1
                                    implicitWidth: keyText.implicitWidth + Style.sizes.spacingMedium * 2
                                    implicitHeight: keyText.implicitHeight + Style.sizes.spacingSmall * 2

                                    Text {
                                      id: keyText
                                      anchors.centerIn: parent
                                      text: keyDelegate.modelData
                                      color: Style.colors.colorOnPrimaryContainer
                                      font.pixelSize: Style.font.pixelSize.smaller
                                      font.family: Style.font.family.monospace
                                      font.weight: Font.Bold
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }

            ColumnLayout {
              spacing: Style.sizes.spacingSmall
              Layout.alignment: Qt.AlignHCenter
              Layout.fillWidth: true

              StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                text: "Above list was generated based on currently defined hyprland bindings."
                color: Style.colors.colorOnSurfaceVariant
                font.pixelSize: Style.font.pixelSize.smaller
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
              }

              Rectangle {
                color: "transparent"
                implicitWidth: openFileText.implicitWidth
                implicitHeight: openFileText.implicitHeight
                Layout.alignment: Qt.AlignHCenter

                StyledText {
                  id: openFileText
                  text: "Open ~/.config/hypr/keybinds.lua for more details"
                  color: Style.colors.primary
                  font.pixelSize: Style.font.pixelSize.smaller
                  font.underline: mouseArea.containsMouse
                  horizontalAlignment: Text.AlignHCenter
                }

                MouseArea {
                  id: mouseArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    Quickshell.execDetached(["xdg-open", Consts.path.config + "/hypr/keybinds.lua"]);
                    GlobalState.osd.cheetsheetOpen = false;
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
