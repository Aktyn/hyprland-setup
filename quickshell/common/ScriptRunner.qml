pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "."

Singleton {
  id: root

  property alias selectWallpaperProcess: selectWallpaperProcess

  Process {
    id: generateColorsProcess
    command: []
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        console.log("Generate material you colors output:", this.text);
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
    //TODO: also customize application styles according to the generated colors

    console.info("Generating json with material you colors based on: " + imagePath);
    generateColorsProcess.command = ["python", Quickshell.shellPath("scripts/generate-material-you-colors.py"), imagePath, Utils.trimFileProtocol(Consts.path.colorsFile)];
    generateColorsProcess.running = true;
  }

  function setHyprlandOption(option: string, value: string) {
    const dynamicConfigFile = Utils.trimFileProtocol(Consts.path.dynamicHyprlandConfig);
    console.info("Setting Hyprland option:", option, "to", value, "in", dynamicConfigFile);

    Quickshell.execDetached(["python", Quickshell.shellPath("scripts/set-hyprland-option.py"), dynamicConfigFile, option, value]);
    Quickshell.execDetached(["hyprctl", "reload"]);
  }

  function copyToClipboard(text: string) {
    Quickshell.execDetached([Quickshell.shellPath("scripts/clip.sh"), text]);
  }
}
