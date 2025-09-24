pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "."

Singleton {
    id: root
    property bool ready: false

    property alias bar: configJsonAdapter.bar

    FileView {
        path: Consts.path.configFile
        watchChanges: true

        onFileChanged: reload()

        onAdapterUpdated: writeAdapter()

        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                writeAdapter()
                reload()
            }
        }

        JsonAdapter {
            id: configJsonAdapter

            property JsonObject bar: JsonObject {
                property int height: 32
                property list<string> screenList: []
            }
        }
    }
}
