import QtQuick
import Quickshell
import Quickshell.Io

import "../../common"
import "../../services"
import "./common"
import "../bar"

BarIconButton {
  toggled: Bluetooth.bluetoothEnabled
  iconName: Bluetooth.bluetoothConnected ? "bluetooth_connected" : Bluetooth.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled"
  onClicked: {
    toggleBluetooth.running = true;
  }
  altAction: () => {
    Quickshell.execDetached(["bash", "-c", `${Config.apps.bluetooth}`]);
  }
  Process {
    id: toggleBluetooth
    command: ["bash", "-c", `rfkill ${Bluetooth.bluetoothEnabled ? "block" : "unblock"} bluetooth && bluetoothctl power ${Bluetooth.bluetoothEnabled ? "off" : "on"}`]
    onRunningChanged: {
      if (!running) {
        Bluetooth.update();
      }
    }
  }
  StyledTooltip {
    content: `${(Bluetooth.bluetoothEnabled && Bluetooth.bluetoothDeviceName.length > 0) ? Bluetooth.bluetoothDeviceName : "Bluetooth"} | Right-click to configure`
    side: StyledTooltip.TooltipSide.Left
  }
}
