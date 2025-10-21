pragma Singleton

import Quickshell
import Quickshell.Services.UPower

import "../common"

Singleton {
  property bool available: UPower.displayDevice.isLaptopBattery
  property var chargeState: UPower.displayDevice.state
  property bool isCharging: chargeState == UPowerDeviceState.Charging
  property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge
  property real percentage: UPower.displayDevice.percentage
  readonly property bool allowAutomaticSuspend: Config.battery.automaticSuspend

  property bool isLow: percentage <= Config.battery.low / 100
  property bool isCritical: percentage <= Config.battery.critical / 100
  property bool isSuspending: percentage <= Config.battery.suspend / 100

  property bool isLowAndNotCharging: isLow && !isCharging
  property bool isCriticalAndNotCharging: isCritical && !isCharging
  property bool isSuspendingAndNotCharging: allowAutomaticSuspend && isSuspending && !isCharging

  onIsLowAndNotChargingChanged: {
    if (available && isLowAndNotCharging)
      Quickshell.execDetached(["notify-send", "Low battery", "Consider plugging in your device", "-u", "critical", "-a", "Shell"]);
  }

  onIsCriticalAndNotChargingChanged: {
    if (available && isCriticalAndNotCharging)
      Quickshell.execDetached(["notify-send", "Critically low battery", "Please charge!", "-u", "critical", "-a", "Shell"]);
  }

  onIsSuspendingAndNotChargingChanged: {
    if (available && isSuspendingAndNotCharging) {
      Quickshell.execDetached(["bash", "-c", `systemctl suspend || loginctl suspend`]);
    }
  }
}
