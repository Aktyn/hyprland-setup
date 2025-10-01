import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import qs.common
import "./common"

Item {
    id: net

    // The network interface to monitor. If empty, auto-detects the default route interface.
    // property string iface: ""
    // property string _detectedIface: ""

    // Update interval in ms
    property int interval: 1000

    // Computed rates in bytes per second
    property real downBps: 0
    property real upBps: 0

    // Internal state
    property real _lastRx: 0
    property real _lastTx: 0
    property real _lastTime: 0
    property bool _primed: false
    // Smoothing configuration: average of last N samples
    property int smoothingWindow: 5
    property var _downHistory: []
    property var _upHistory: []
    // Hide when both directions are below a threshold (in bytes per second)

    //TODO: move to Config
    property real hideThresholdDownloadBps: 500 * 1024
    property real hideThresholdUploadBps: 50 * 1024

    Layout.fillHeight: true
    implicitHeight: Config.bar.height
    implicitWidth: row.implicitWidth + row.spacing * 2

    Timer {
        id: tick
        interval: net.interval
        running: true
        repeat: true
        onTriggered: {
            // if (!net.iface || net.iface.length === 0) {
            //     detectInterface.startCheck()
            // } else {
            //     readStats.startCheck()
            // }
            readStats.startCheck()
        }
    }

    // Detect the primary/default interface via ip route
    // Process {
    //     id: detectInterface
    //     property string buffer: ""
    //     command: ["bash", "-lc", "ip route | awk '/default/ && /dev/ {for(i=1;i<=NF;i++) if ($i==\"dev\") {print $(i+1); exit}}'"]
    //     running: false
    //     function startCheck() {
    //         buffer = ""
    //         running = true
    //     }
    //     stdout: SplitParser {
    //         onRead: data => detectInterface.buffer += data
    //     }
    //     onExited: (code, status) => {
    //         const found = detectInterface.buffer.trim()
    //         if (found.length > 0 && found !== net._detectedIface) {
    //             net._detectedIface = found
    //             net.iface = found
    //             // Reset stats when iface changes
    //             net._primed = false
    //             net._lastRx = 0
    //             net._lastTx = 0
    //         }
    //     }
    // }

    // Read rx/tx bytes for the selected interface
    Process {
        id: readStats
        property string buffer: ""
        //TODO: retrieve the interface dynamically
        command: "cat /sys/class/net/enp5s0/statistics/rx_bytes /sys/class/net/enp5s0/statistics/tx_bytes 2>/dev/null".split(/\s+/)
        running: false
        function startCheck() {
            readStats.buffer = ""
            // if (net.iface && net.iface !== "lo") {
            //     running = true
            // }
            readStats.running = true
        }
        stdout: SplitParser {
            onRead: data => readStats.buffer += data + "\n"
        }
        onExited: (code, status) => {
            const parts = readStats.buffer.trim().split('\n')
            if (parts.length >= 2) {
                const rx = parseFloat(parts[0])
                const tx = parseFloat(parts[1])
                const now = Date.now()
                if (net._primed) {
                    let dt = (now - net._lastTime) / 1000.0
                    if (dt <= 0 || !isFinite(dt)) dt = net.interval / 1000.0
                    const dRx = rx - net._lastRx
                    const dTx = tx - net._lastTx
                    const rawDown = Math.max(0, isFinite(dRx) ? dRx / dt : 0)
                    const rawUp = Math.max(0, isFinite(dTx) ? dTx / dt : 0)

                    // Update histories
                    net._downHistory.push(rawDown)
                    net._upHistory.push(rawUp)
                    while (net._downHistory.length > net.smoothingWindow) net._downHistory.shift()
                    while (net._upHistory.length > net.smoothingWindow) net._upHistory.shift()

                    // Compute averages
                    let sumD = 0
                    for (let i = 0; i < net._downHistory.length; i++) sumD += net._downHistory[i]
                    let sumU = 0
                    for (let i = 0; i < net._upHistory.length; i++) sumU += net._upHistory[i]

                    net.downBps = net._downHistory.length > 0 ? sumD / net._downHistory.length : rawDown
                    net.upBps = net._upHistory.length > 0 ? sumU / net._upHistory.length : rawUp
                } else {
                    // First sample after reset; clear histories
                    net._downHistory = []
                    net._upHistory = []
                }
                net._lastRx = rx
                net._lastTx = tx
                net._lastTime = now
                net._primed = true
            } else {
                // Could not read stats; reset and set to zero
                net.downBps = 0
                net.upBps = 0
                net._downHistory = []
                net._upHistory = []
                net._primed = false
            }
        }
    }

    function formatRate(bps) {
        if (!isFinite(bps) || bps <= 0) return "0 B/s"
        const units = ["B/s", "KB/s", "MB/s", "GB/s", "TB/s"]
        let u = 0
        let v = bps
        while (v >= 1024 && u < units.length - 1) {
            v /= 1024
            u++
        }
        const digits = u === 0 ? 0 : (v < 10 ? 1 : 0)
        return v.toFixed(digits) + " " + units[u]
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        // Download group (icon + text)
        Item {
            id: downGroup
            // Drive show/hide from your condition
            readonly property bool shown: net.downBps > net.hideThresholdDownloadBps

            // Animate appearance
            opacity: shown ? 1 : 0
            // Collapse in layout when hidden
            Layout.preferredWidth: shown ? implicitWidth : 0
            // Only render when not fully transparent
            visible: opacity > 0.001

            // Keep its implicit sizes based on content
            implicitWidth: downRow.implicitWidth
            implicitHeight: downRow.implicitHeight

            // Optional small slide-in/out for polish
            x: shown ? 0 : -6

            Behavior on opacity {
                NumberAnimation {
                    duration: Style.animation.elementMoveFast.duration
                    easing.type: Style.animation.elementMoveFast.type
                    // easing.bezierCurve: Style.animation.elementMoveFast.bezierCurve
                }
            }
            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Style.animation.elementMoveFast.duration
                    easing.type: Style.animation.elementMoveFast.type
                    // easing.bezierCurve: Style.animation.elementMoveFast.bezierCurve
                }
            }
            Behavior on x {
                NumberAnimation {
                    duration: Style.animation.elementMoveFast.duration
                    easing.type: Style.animation.elementMoveFast.type
                    // easing.bezierCurve: Style.animation.elementMoveFast.bezierCurve
                }
            }

            RowLayout {
                id: downRow
                spacing: 6

                MaterialSymbol {
                    text: "south" // download
                    iconSize: Style.font.pixelSize.small
                    color: Style.colors.colorOnSecondaryContainer
                }
                StyledText {
                    text: net.formatRate(net.downBps)
                    font.pixelSize: Style.font.pixelSize.smaller
                    color: Style.colors.colorOnSecondaryContainer
                }
            }
        }

        // Upload group (icon + text)
        Item {
            id: upGroup
            readonly property bool shown: net.upBps > net.hideThresholdUploadBps

            opacity: shown ? 1 : 0
            Layout.preferredWidth: shown ? implicitWidth : 0
            visible: opacity > 0.001

            implicitWidth: upRow.implicitWidth
            implicitHeight: upRow.implicitHeight

            x: shown ? 0 : -6

            Behavior on opacity {
                NumberAnimation {
                    duration: Style.animation.elementMoveFast.duration
                    easing.type: Style.animation.elementMoveFast.type
                    // easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
            Behavior on Layout.preferredWidth {
                NumberAnimation {
                    duration: Style.animation.elementMoveFast.duration
                    easing.type: Style.animation.elementMoveFast.type
                    // easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
            Behavior on x {
                NumberAnimation {
                    duration: Style.animation.elementMoveFast.duration
                    easing.type: Style.animation.elementMoveFast.type
                    // easing.bezierCurve: Style.animation.elementMoveFast.bezierCurve
                }
            }

            RowLayout {
                id: upRow
                spacing: 6

                MaterialSymbol {
                    text: "north" // upload
                    iconSize: Style.font.pixelSize.small
                    color: Style.colors.colorOnSecondaryContainer
                }
                StyledText {
                    text: net.formatRate(net.upBps)
                    font.pixelSize: Style.font.pixelSize.smaller
                    color: Style.colors.colorOnSecondaryContainer
                }
            }
        }
    }
}
