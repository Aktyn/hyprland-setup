pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "."

Singleton {
  id: root

  property alias selectWallpaperProcess: selectWallpaperProcess

  function parseScriptStdout(output: string): string {
    return output.split("\n").map(line => `\t${line}`).join("\n");
  }

  Process {
    id: generateColorsProcess
    command: []
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        console.log("generateColorsProcess output:\n", root.parseScriptStdout(this.text));

        adjustSystemColorsProcess.running = true;
      }
    }
  }

  Process {
    id: adjustSystemColorsProcess
    command: ["python", Quickshell.shellPath("scripts/adjust-system-colors.py"), Utils.trimFileProtocol(Consts.path.colorsFile)]
    workingDirectory: Quickshell.shellPath("scripts")
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        console.log("adjustSystemColorsProcess output:\n", root.parseScriptStdout(this.text));

        Quickshell.execDetached(["hyprctl", "reload"]);
      }
    }
  }

  Process {
    id: selectWallpaperProcess
    command: ["bash", "-c", "kdialog --getopenfilename ~/Pictures \"Images (*.png *.jpg *.jpeg *.gif *.bmp *.webp *.tif *.tiff *.svg);;All files (*)\""]
    running: false

    stdout: StdioCollector {
      onStreamFinished: {
        const path = this.text.trim();
        if (!path) {
          return;
        }

        console.info("New wallpaper selected:", path);
        Config.wallpaper.path = path;
      }
    }
  }

  function generateMaterialYouColors(imagePath) {
    console.info("Generating json with material you colors based on: " + imagePath);
    generateColorsProcess.command = ["python", Quickshell.shellPath("scripts/generate-material-you-colors.py"), imagePath, Utils.trimFileProtocol(Consts.path.colorsFile)];
    generateColorsProcess.running = true;
  }

  function copyToClipboard(text: string) {
    Quickshell.execDetached([Quickshell.shellPath("scripts/clip.sh"), text]);
  }
}
