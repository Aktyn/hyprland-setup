pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.common

Singleton {
  id: root

  Process {
    id: proc
    command: []
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        console.log(this.text)
      }
    }
  }

  function generateMaterialYouColors(imagePath) {
    //TODO: also update hyprland border colors and customize application styles according to the generated colors

    console.info("Generating json with material you colors based on: " + imagePath);
    const output = Consts.path.colorsFile.replace(/^file:\/\//, "")
    proc.command = ["python", Quickshell.shellPath("scripts/generate-material-you-colors.py"), imagePath, output];
    proc.running = true;
  }
}
