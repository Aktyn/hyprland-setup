import QtQuick
import QtQuick.Layouts
import Quickshell.Io

import "../../common"
import "./common"

Item {
  id: net

  // Computed rates in bytes per second
  property real downBps: 0
  property real upBps: 0

  // Internal state
  property string _lastIfaceKey: ""
  property real _lastRx: 0
  property real _lastTx: 0
  property real _lastTime: 0
  property bool _primed: false

  // Update interval in ms
  property int interval: 1000
  // Smoothing configuration: average of last N samples
  property int smoothingWindow: 10 // 10 * 1000ms gives a 10-second weighted average of network speeds
  property var _downHistory: []
  property var _upHistory: []

  //TODO:: move to Config
  // Hide when both directions are below a threshold (in bytes per second)
  property real hideThresholdDownloadBps: 500 * 1024
  property real hideThresholdUploadBps: 50 * 1024

  Layout.fillHeight: true
  implicitHeight: Config.bar.height
  implicitWidth: row.implicitWidth + row.spacing * 2

  FileView {
    id: fileNetRoute
    path: "/proc/net/route"
  }

  FileView {
    id: fileNetDev
    path: "/proc/net/dev"
  }

  Timer {
    id: tick
    interval: net.interval
    running: true
    repeat: true
    onTriggered: {
      // 1. Find default interfaces with lowest metric from /proc/net/route
      fileNetRoute.reload();
      const routeText = fileNetRoute.text();
      const routeLines = routeText.split('\n');
      let minMetric = 999999;
      let bestIfaces = [];

      for (let i = 1; i < routeLines.length; i++) {
        const line = routeLines[i].trim();
        if (line === "") continue;
        const parts = line.split(/\s+/);
        if (parts.length > 6 && parts[1] === "00000000") {
          const metric = parseInt(parts[6]);
          if (metric < minMetric) {
            minMetric = metric;
            bestIfaces = [parts[0]];
          } else if (metric === minMetric) {
            bestIfaces.push(parts[0]);
          }
        }
      }

      // 2. Detect if the set of interfaces changed to reset smoothing
      const ifaceKey = bestIfaces.sort().join(',');
      if (ifaceKey !== net._lastIfaceKey) {
        net._lastIfaceKey = ifaceKey;
        net._primed = false;
      }

      if (bestIfaces.length === 0) {
        net.downBps = 0;
        net.upBps = 0;
        net._primed = false;
        return;
      }

      // 3. Sum stats for these interfaces from /proc/net/dev
      fileNetDev.reload();
      const devText = fileNetDev.text();
      const devLines = devText.split('\n');
      let rx = 0;
      let tx = 0;
      let foundAny = false;

      for (const line of devLines) {
        const parts = line.trim().split(/[:\s]+/);
        if (parts.length > 9 && bestIfaces.indexOf(parts[0]) !== -1) {
          rx += parseInt(parts[1]) || 0;
          tx += parseInt(parts[9]) || 0;
          foundAny = true;
        }
      }

      // 4. Calculate rates and update smoothing
      if (foundAny) {
        const now = Date.now();
        if (net._primed) {
          let dt = (now - net._lastTime) / 1000.0;
          if (dt <= 0 || !isFinite(dt))
            dt = net.interval / 1000.0;
          const dRx = rx - net._lastRx;
          const dTx = tx - net._lastTx;
          const rawDown = Math.max(0, isFinite(dRx) ? dRx / dt : 0);
          const rawUp = Math.max(0, isFinite(dTx) ? dTx / dt : 0);

          // Update histories
          net._downHistory.push(rawDown);
          net._upHistory.push(rawUp);
          while (net._downHistory.length > net.smoothingWindow)
            net._downHistory.shift();
          while (net._upHistory.length > net.smoothingWindow)
            net._upHistory.shift();

          // Compute averages
          const downAverage = Utils.linearlyWeighterAverage(net._downHistory);
          const upAverage = Utils.linearlyWeighterAverage(net._upHistory);

          net.downBps = net._downHistory.length > 0 ? downAverage : rawDown;
          net.upBps = net._upHistory.length > 0 ? upAverage : rawUp;
        } else {
          // First sample after reset; clear histories
          net._downHistory = [];
          net._upHistory = [];
        }
        net._lastRx = rx;
        net._lastTx = tx;
        net._lastTime = now;
        net._primed = true;
      } else {
        // Could not read stats; reset and set to zero
        net.downBps = 0;
        net.upBps = 0;
        net._downHistory = [];
        net._upHistory = [];
        net._primed = false;
      }
    }
  }

  function formatRate(bps) {
    if (!isFinite(bps) || bps <= 0)
      return "0 B/s";
    const units = ["B/s", "KB/s", "MB/s", "GB/s", "TB/s"];
    let u = 0;
    let v = bps;
    while (v >= 1024 && u < units.length - 1) {
      v /= 1024;
      u++;
    }
    const digits = u === 0 ? 0 : (v < 10 ? 1 : 0);
    return v.toFixed(digits) + " " + units[u];
  }

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: Style.sizes.spacingMedium

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

      Behavior on opacity {
        NumberAnimation {
          duration: Style.animation.elementMoveFast.duration
          easing.type: Style.animation.elementMoveFast.type
        }
      }
      Behavior on Layout.preferredWidth {
        NumberAnimation {
          duration: Style.animation.elementMoveFast.duration
          easing.type: Style.animation.elementMoveFast.type
        }
      }

      RowLayout {
        id: downRow
        spacing: Style.sizes.spacingSmall

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

      Behavior on opacity {
        NumberAnimation {
          duration: Style.animation.elementMoveFast.duration
          easing.type: Style.animation.elementMoveFast.type
        }
      }
      Behavior on Layout.preferredWidth {
        NumberAnimation {
          duration: Style.animation.elementMoveFast.duration
          easing.type: Style.animation.elementMoveFast.type
        }
      }

      RowLayout {
        id: upRow
        spacing: Style.sizes.spacingSmall

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
