pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "."

Singleton {
  id: root

  Process {
    id: proc
    command: []
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        console.log("Generate material you colors output:", this.text);
      }
    }
  }

  //TODO: also customize application styles according to the generated colors
  function generateMaterialYouColors(imagePath) {
    console.info("Generating json with material you colors based on: " + imagePath);
    proc.command = ["python", Quickshell.shellPath("scripts/generate-material-you-colors.py"), imagePath, Utils.trimFileProtocol(Consts.path.colorsFile)];
    proc.running = true;
  }

  function setHyprlandOption(option: string, value: string) {
    const dynamicConfigFile = Utils.trimFileProtocol(Consts.path.dynamicHyprlandConfig);
    console.info("Setting Hyprland option:", option, "to", value, "in", dynamicConfigFile);

    Quickshell.execDetached(["python", Quickshell.shellPath("scripts/set-hyprland-option.py"), dynamicConfigFile, option, value]);
    Quickshell.execDetached(["hyprctl", "reload"]);
  }
}
