/*
 * SDDM Material Design Theme
 * Based on Material Design principles for a clean and modern look.
 */

import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: container
    width: 1920
    height: 1080
    color: "#121212" // Dark Material background

    property string themePath: themeDir.path + "/"

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    TextConstants {
        id: textConstants
    }

    Connections {
        target: sddm
        onLoginSucceeded: {
            message.text = textConstants.loginSucceeded;
            message.color = "#4CAF50"; // Material Green
        }
        onLoginFailed: {
            message.text = textConstants.loginFailed;
            message.color = "#F44336"; // Material Red
            passwordInput.text = "";
        }
    }

    // Background Image
    Background {
        id: background
        anchors.fill: parent
        source: themePath + "maldives.jpg"
        fillMode: Image.PreserveAspectCrop
        onStatusChanged: {
            if (status == Image.Error) {
                // Fallback to a solid color if the image fails to load
                container.color = "#1E1E1E";
            }
        }
    }

    // Dimming overlay
    Rectangle {
        anchors.fill: parent
        color: "#80000000"
    }

    // Clock
    Clock {
        id: clock
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 24
        color: "white"
        timeFont.family: "Roboto"
        timeFont.pointSize: 18
    }

    // Main Login Form Container
    Rectangle {
        id: loginForm
        width: 380
        height: 500
        anchors.centerIn: parent
        color: "#2E2E2E" // Dark surface color
        radius: 16
        border.color: "#3E3E3E"
        border.width: 1

        Column {
            id: formElements
            anchors.centerIn: parent
            width: parent.width - 64
            spacing: 20

            // Welcome Header
            Text {
                width: parent.width
                text: "Welcome Back"
                color: "white"
                font.family: "Roboto"
                font.pointSize: 26
                font.weight: Font.Light
                horizontalAlignment: Text.AlignHCenter
                bottomPadding: 10
            }

            // --- Custom Username Input ---
            Rectangle {
                width: parent.width
                height: 50
                color: "#3E3E3E"
                radius: 8

                TextInput {
                    id: nameInput
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    focus: true
                    text: userModel.lastUser
                    color: "white"
                    font.pointSize: 12
                    verticalAlignment: Text.AlignVCenter
                    KeyNavigation.tab: passwordInput
                }

                Text {
                    text: textConstants.userName
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#BDBDBD"
                    font.pointSize: 12
                    visible: nameInput.text === ""
                }
            }

            // --- Custom Password Input ---
            Rectangle {
                width: parent.width
                height: 50
                color: "#3E3E3E"
                radius: 8

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    echoMode: TextInput.Password
                    color: "white"
                    font.pointSize: 12
                    verticalAlignment: Text.AlignVCenter
                    KeyNavigation.tab: session.model.count > 1 ? session : loginButton

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            sddm.login(nameInput.text, passwordInput.text, session.index);
                            event.accepted = true;
                        }
                    }
                }

                Text {
                    text: textConstants.password
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#BDBDBD"
                    font.pointSize: 12
                    visible: passwordInput.text === ""
                }
            }

            // Session ComboBox
            ComboBox {
                id: session
                width: parent.width
                height: 50
                font.pointSize: 12
                model: sessionModel
                index: sessionModel.lastIndex
                visible: model.count > 1

                // background: Rectangle {
                //     color: "#3E3E3E"
                //     radius: 8
                // }

                arrowIcon: "angle-down.png"
                KeyNavigation.tab: loginButton
            }

            // Login Button
            Rectangle {
                id: loginButton
                width: parent.width
                height: 50
                radius: 25
                color: "#007BFF"

                Text {
                    text: textConstants.login
                    anchors.centerIn: parent
                    color: "white"
                    font.pointSize: 14
                    font.bold: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sddm.login(nameInput.text, passwordInput.text, session.index)
                }
            }

            // Error/Info Message
            Text {
                id: message
                width: parent.width
                text: textConstants.prompt
                color: "#BDBDBD"
                font.pointSize: 10
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }
    }

    // System Buttons
    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: 24
        spacing: 20

        Rectangle {
            // Shutdown Button
            width: 120
            height: 40
            color: "transparent"
            radius: 20
            border.color: "#BDBDBD"
            border.width: 1
            Text {
                text: textConstants.shutdown
                anchors.centerIn: parent
                color: "#BDBDBD"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: sddm.powerOff()
                cursorShape: Qt.PointingHandCursor
            }
        }

        Rectangle {
            // Reboot Button
            width: 120
            height: 40
            color: "transparent"
            radius: 20
            border.color: "#BDBDBD"
            border.width: 1
            Text {
                text: textConstants.reboot
                anchors.centerIn: parent
                color: "#BDBDBD"
            }
            MouseArea {
                anchors.fill: parent
                onClicked: sddm.reboot()
                cursorShape: Qt.PointingHandCursor
            }
        }
    }

    Component.onCompleted: {
        if (nameInput.text === "") {
            nameInput.focus = true;
        } else {
            passwordInput.focus = true;
        }
    }
}
