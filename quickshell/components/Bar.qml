import "./widgets/"
import "../common/"

import QtQuick
import Quickshell
import QtQuick.Layouts

Scope {
    id: bar

    property string time

    Variants {
        model: {
            if (Config.bar.screenList.length === 0
                    && Hyprland.monitors.length > 0) {
                Config.bar.screenList = Hyprland.monitors.map(m => m.name)
            }

            const screens = Quickshell.screens

            const list = screens.filter(
                      screen => Config.bar.screenList.includes(screen.name))
            if (list.length > 0) {
                return list
            }

            return screens
        }

        delegate: Component {
            PanelWindow {
                required property var modelData

                screen: modelData
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: Config.bar.height
                aboveWindows: false //TODO: change to true if some areas can be made to ignore pointer events
                color: "transparent"

                implicitHeight: Config.bar.height + Hyprland.decoration.rounding
                                + Hyprland.general.gapsOut[0]

                anchors {
                    top: true
                    left: true
                    right: true
                }

                // Rounded decorators
                Item {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: barLayout.bottom
                    }

                    ReversedRoundedCorner {
                        anchors {
                            top: parent.top
                            left: parent.left
                        }

                        corner: ReversedRoundedCorner.CornerEnum.TopLeft
                    }

                    ReversedRoundedCorner {
                        anchors {
                            top: parent.top
                            right: parent.right
                        }

                        corner: ReversedRoundedCorner.CornerEnum.TopRight
                    }
                }

                Item {
                    id: barLayout

                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    implicitHeight: Config.bar.height

                    // Background
                    Rectangle {
                        // id: barBackground
                        anchors {
                            fill: parent
                        }
                        color: Style.colors.barBackground
                        implicitHeight: Config.bar.height

                        // radius: Hyprland.decoration.rounding
                        topLeftRadius: Hyprland.decoration.rounding
                        topRightRadius: Hyprland.decoration.rounding
                    }

                    RowLayout {
                        spacing: 8
                        anchors.fill: parent

                        ClockWidget {
                            Layout.leftMargin: Hyprland.decoration.rounding / 2
                        }

                        // Text {
                        //     text: "Rounding: " + Hyprland.decoration.rounding
                        //           + ", path: " + Consts.path.configFile
                        //     Layout.rightMargin: Hyprland.decoration.rounding / 2
                        // }
                    }
                }
            }
        }
    }
}
