pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

import "../../common"
import "../../services"

import "../widgets/common"

Scope {
  id: root
  property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)

  Loader {
    active: GlobalState.osd.clipboardPanelOpen

    sourceComponent: Scope {
      PanelWindow {
        id: pointerCatcher

        screen: root.focusedScreen
        anchors {
          top: true
          bottom: true
          left: true
          right: true
        }

        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        visible: GlobalState.osd.clipboardPanelOpen

        color: "transparent"

        MouseArea {
          anchors.fill: parent
          onClicked: {
            GlobalState.osd.clipboardPanelOpen = false;
          }
        }
      }

      PanelWindow {
        id: osdRoot

        Connections {
          target: root
          function onFocusedScreenChanged() {
            osdRoot.screen = root.focusedScreen;
          }
        }

        HyprlandFocusGrab {
          id: grab
          windows: [osdRoot]

          onActiveChanged: {
            if (!this.active) {
              GlobalState.osd.clipboardPanelOpen = false;
            }
          }
        }

        exclusionMode: ExclusionMode.Normal
        WlrLayershell.namespace: "quickshell:onScreenDisplay"
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"

        anchors {
          top: true
        }
        mask: Region {
          item: osdValuesWrapper
        }

        implicitWidth: columnLayout.implicitWidth
        implicitHeight: columnLayout.implicitHeight
        visible: GlobalState.osd.clipboardPanelOpen

        ColumnLayout {
          id: columnLayout

          Rectangle {
            id: osdValuesWrapper

            readonly property int padding: Style.sizes.spacingMedium

            Layout.topMargin: padding
            implicitHeight: layout.implicitHeight + padding * 2
            implicitWidth: layout.implicitWidth + padding * 2

            clip: true

            color: Style.colors.surfaceContainer
            border.color: Style.colors.outlineVariant
            radius: Style.rounding.normal

            ColumnLayout {
              id: layout
              anchors.centerIn: parent
              spacing: osdValuesWrapper.padding

              SearchField {
                id: clipboardSearch

                Layout.fillWidth: true
                Layout.minimumWidth: 384
                placeholder: "Search clipboard history"
                radius: osdValuesWrapper.radius - osdValuesWrapper.padding

                Component.onCompleted: {
                  if (GlobalState.osd.clipboardPanelOpen) {
                    clipboardSearch.focusInput();
                    grab.active = true;
                  }
                }

                onHasFocusChanged: function () {
                  grab.active = this.hasFocus;
                }
              }

              ScrollView {
                id: scrollView

                Layout.maximumHeight: Math.min(Screen.height * 0.5, 512)

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ListView {
                  id: listView

                  Layout.fillWidth: true
                  spacing: Style.sizes.spacingSmall
                  model: {
                    return ClipboardHistory.fuzzyQuery(clipboardSearch.searchText).filter(Boolean).map(entry => {
                      return clipboardEntryComponent.createObject(root, {
                        rawString: entry,
                        name: entry.replace(/^\s*\S+\s+/, ""),
                        type: `#${entry.match(/^\s*(\S+)/)?.[1] || ""}`
                      });
                    });
                  }

                  delegate: Text {
                    required property ClipboardEntryObject modelData
                    text: modelData.name
                  }
                  // delegate: EntryItem {
                  //   anchors.left: parent?.left
                  //   anchors.right: parent?.right

                  //   entry: modelData
                  //   toggled: GlobalState.leftSidebar.appSearch.selectedEntryIndex === index
                  // }
                }
              }
            }
          }
        }
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
    }
    function remove() {
      ClipboardHistory.deleteEntry(this.rawString);
    }
  }

  Component {
    id: clipboardEntryComponent
    ClipboardEntryObject {}
  }

  GlobalShortcut {
    name: "overviewClipboardToggle"
    description: "Toggle clipboard query on overview widget"

    onPressed: {
      GlobalState.osd.clipboardPanelOpen = !GlobalState.osd.clipboardPanelOpen;
    }
  }
}
