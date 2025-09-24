pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {

    id: root

    property QtObject colors: QtObject {
        property string barBackground: "#123"
    }
}
