pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import "../services"
import "."

Singleton {
  id: root

  property alias colors: colorsJsonAdapter.colors
  property alias wallpaper: colorsJsonAdapter.wallpaper
  property alias isDark: colorsJsonAdapter.is_dark

  property QtObject font: QtObject {
    property QtObject family: QtObject {
      property string main: "Rubik"
      property string title: "Gabarito"
      property string iconMaterial: "Material Symbols Rounded"
      property string iconNerd: "SpaceMono NF"
      property string monospace: "JetBrains Mono NF"
      property string reading: "Readex Pro"
      property string expressive: "Space Grotesk"
    }
    //TODO: refactor this names and get rid of unused ones
    property QtObject pixelSize: QtObject {
      property int smallest: 10
      property int smaller: 12
      property int small: 15
      property int normal: 16
      property int large: 17
      property int larger: 19
      property int huge: 22
      property int hugeass: 23
      property int title: huge
    }
  }

  property QtObject rounding: QtObject {
    property int unsharpen: 2
    property int unsharpenmore: 6
    property int verysmall: 8
    property int small: 12
    property int normal: 17
    property int large: 23
    property int verylarge: 30
    property int full: 9999
    property int screenRounding: large
    property int windowRounding: 18
    property int hyprland: HyprlandInfo.decoration.rounding
  }

  property QtObject sizes: QtObject {
    property int spacingExtraSmall: 2
    property int spacingSmall: 4
    property int spacingMedium: 8
    property int spacingLarge: 16
    property int spacingExtraLarge: 24

    property int heightMedium: 20
    property int heightLarge: 24
    property int heightExtraLarge: 32

    property int iconMedium: heightMedium
    property int iconLarge: heightLarge
    property int iconExtraLarge: heightExtraLarge
  }

  property QtObject animation: QtObject {
    property QtObject elementMove: QtObject {
      property int duration: 500
      property int type: Easing.InOutQuad

      property Component numberAnimation: Component {
        NumberAnimation {
          duration: root.animation.elementMove.duration
          easing.type: root.animation.elementMove.type
        }
      }
      property Component colorAnimation: Component {
        ColorAnimation {
          duration: root.animation.elementMove.duration
          easing.type: root.animation.elementMove.type
        }
      }
    }

    property QtObject elementMoveFast: QtObject {
      property int duration: 200
      property int type: Easing.InOutQuad
      property int velocity: 850
      property Component colorAnimation: Component {
        ColorAnimation {
          duration: root.animation.elementMoveFast.duration
          easing.type: root.animation.elementMoveFast.type
        }
      }
      property Component numberAnimation: Component {
        NumberAnimation {
          duration: root.animation.elementMoveFast.duration
          easing.type: root.animation.elementMoveFast.type
        }
      }
    }

    // property QtObject clickBounce: QtObject {
    //   property int duration: 200
    //   property int type: Easing.BezierSpline
    //   property list<real> bezierCurve: animationCurves.expressiveFastSpatial
    //   property int velocity: 850
    //   property Component numberAnimation: Component {
    //     NumberAnimation {
    //       duration: root.animation.clickBounce.duration
    //       easing.type: root.animation.clickBounce.type
    //       easing.bezierCurve: root.animation.clickBounce.bezierCurve
    //     }
    //   }
    // }
  }

  FileView {
    path: Consts.path.colorsFile
    watchChanges: true

    onFileChanged: {
      reload();
    }

    onAdapterUpdated: writeAdapter()

    onLoaded: {
      Colors.ready = true;
    }
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound) {
        writeAdapter();
        reload();
      }
    }

    JsonAdapter {
      id: colorsJsonAdapter

      property JsonObject colors: JsonObject {
        property string primary_paletteKeyColor: "#6f72ad"
        property string secondary_paletteKeyColor: "#75758b"
        property string tertiary_paletteKeyColor: "#936b83"
        property string neutral_paletteKeyColor: "#77767d"
        property string neutral_variant_paletteKeyColor: "#777680"
        property string background: "#131318"
        property string colorOnBackground: "#e4e1e9"
        property string surface: "#131318"
        property string surfaceDim: "#131318"
        property string surfaceBright: "#39383f"
        property string surfaceContainerLowest: "#0e0e13"
        property string surfaceContainerLow: "#1b1b21"
        property string surfaceContainer: "#1f1f25"
        property string surfaceContainerHigh: "#2a292f"
        property string surfaceContainerHighest: "#35343a"
        property string colorOnSurface: "#e4e1e9"
        property string surfaceVariant: "#46464f"
        property string colorOnSurfaceVariant: "#c7c5d0"
        property string inverseSurface: "#e4e1e9"
        property string inverseOnSurface: "#303036"
        property string outline: "#918f9a"
        property string outlineVariant: "#46464f"
        property string shadow: "#000000"
        property string scrim: "#000000"
        property string surfaceTint: "#bfc2ff"
        property string primary: "#bfc2ff"
        property string colorOnPrimary: "#272b60"
        property string primaryContainer: "#3e4278"
        property string colorOnPrimaryContainer: "#e0e0ff"
        property string inversePrimary: "#565992"
        property string secondary: "#c5c4dd"
        property string colorOnSecondary: "#2e2f42"
        property string secondaryContainer: "#444559"
        property string colorOnSecondaryContainer: "#e1e0f9"
        property string tertiary: "#e8b9d4"
        property string colorOnTertiary: "#46263b"
        property string tertiaryContainer: "#af849e"
        property string colorOnTertiaryContainer: "#000000"
        property string error: "#ffb4ab"
        property string colorOnError: "#690005"
        property string errorContainer: "#93000a"
        property string colorOnErrorContainer: "#ffdad6"
        property string primaryFixed: "#e0e0ff"
        property string primaryFixedDim: "#bfc2ff"
        property string colorOnPrimaryFixed: "#11144b"
        property string colorOnPrimaryFixedVariant: "#3e4278"
        property string secondaryFixed: "#e1e0f9"
        property string secondaryFixedDim: "#c5c4dd"
        property string colorOnSecondaryFixed: "#191a2c"
        property string colorOnSecondaryFixedVariant: "#444559"
        property string tertiaryFixed: "#ffd8ed"
        property string tertiaryFixedDim: "#e8b9d4"
        property string colorOnTertiaryFixed: "#2e1125"
        property string colorOnTertiaryFixedVariant: "#5f3c52"
        property string primary_paletteKeyColorDark: "#6f72ad"
        property string secondary_paletteKeyColorDark: "#75758b"
        property string tertiary_paletteKeyColorDark: "#936b83"
        property string neutral_paletteKeyColorDark: "#77767d"
        property string neutral_variant_paletteKeyColorDark: "#777680"
        property string backgroundDark: "#131318"
        property string colorOnBackgroundDark: "#e4e1e9"
        property string surfaceDark: "#131318"
        property string surfaceDimDark: "#131318"
        property string surfaceBrightDark: "#39383f"
        property string surfaceContainerLowestDark: "#0e0e13"
        property string surfaceContainerLowDark: "#1b1b21"
        property string surfaceContainerDark: "#1f1f25"
        property string surfaceContainerHighDark: "#2a292f"
        property string surfaceContainerHighestDark: "#35343a"
        property string colorOnSurfaceDark: "#e4e1e9"
        property string surfaceVariantDark: "#46464f"
        property string colorOnSurfaceVariantDark: "#c7c5d0"
        property string inverseSurfaceDark: "#e4e1e9"
        property string inverseOnSurfaceDark: "#303036"
        property string outlineDark: "#918f9a"
        property string outlineVariantDark: "#46464f"
        property string shadowDark: "#000000"
        property string scrimDark: "#000000"
        property string surfaceTintDark: "#bfc2ff"
        property string primaryDark: "#bfc2ff"
        property string colorOnPrimaryDark: "#272b60"
        property string primaryContainerDark: "#3e4278"
        property string colorOnPrimaryContainerDark: "#e0e0ff"
        property string inversePrimaryDark: "#565992"
        property string secondaryDark: "#c5c4dd"
        property string colorOnSecondaryDark: "#2e2f42"
        property string secondaryContainerDark: "#444559"
        property string colorOnSecondaryContainerDark: "#e1e0f9"
        property string tertiaryDark: "#e8b9d4"
        property string colorOnTertiaryDark: "#46263b"
        property string tertiaryContainerDark: "#af849e"
        property string colorOnTertiaryContainerDark: "#000000"
        property string errorDark: "#ffb4ab"
        property string colorOnErrorDark: "#690005"
        property string errorContainerDark: "#93000a"
        property string colorOnErrorContainerDark: "#ffdad6"
        property string primaryFixedDark: "#e0e0ff"
        property string primaryFixedDimDark: "#bfc2ff"
        property string colorOnPrimaryFixedDark: "#11144b"
        property string colorOnPrimaryFixedVariantDark: "#3e4278"
        property string secondaryFixedDark: "#e1e0f9"
        property string secondaryFixedDimDark: "#c5c4dd"
        property string colorOnSecondaryFixedDark: "#191a2c"
        property string colorOnSecondaryFixedVariantDark: "#444559"
        property string tertiaryFixedDark: "#ffd8ed"
        property string tertiaryFixedDimDark: "#e8b9d4"
        property string colorOnTertiaryFixedDark: "#2e1125"
        property string colorOnTertiaryFixedVariantDark: "#5f3c52"
        property string primary_paletteKeyColorLight: "#6f72ad"
        property string secondary_paletteKeyColorLight: "#75758b"
        property string tertiary_paletteKeyColorLight: "#936b83"
        property string neutral_paletteKeyColorLight: "#77767d"
        property string neutral_variant_paletteKeyColorLight: "#777680"
        property string backgroundLight: "#131318"
        property string colorOnBackgroundLight: "#e4e1e9"
        property string surfaceLight: "#131318"
        property string surfaceDimLight: "#131318"
        property string surfaceBrightLight: "#39383f"
        property string surfaceContainerLowestLight: "#0e0e13"
        property string surfaceContainerLowLight: "#1b1b21"
        property string surfaceContainerLight: "#1f1f25"
        property string surfaceContainerHighLight: "#2a292f"
        property string surfaceContainerHighestLight: "#35343a"
        property string colorOnSurfaceLight: "#e4e1e9"
        property string surfaceVariantLight: "#46464f"
        property string colorOnSurfaceVariantLight: "#c7c5d0"
        property string inverseSurfaceLight: "#e4e1e9"
        property string inverseOnSurfaceLight: "#303036"
        property string outlineLight: "#918f9a"
        property string outlineVariantLight: "#46464f"
        property string shadowLight: "#000000"
        property string scrimLight: "#000000"
        property string surfaceTintLight: "#bfc2ff"
        property string primaryLight: "#bfc2ff"
        property string colorOnPrimaryLight: "#272b60"
        property string primaryContainerLight: "#3e4278"
        property string colorOnPrimaryContainerLight: "#e0e0ff"
        property string inversePrimaryLight: "#565992"
        property string secondaryLight: "#c5c4dd"
        property string colorOnSecondaryLight: "#2e2f42"
        property string secondaryContainerLight: "#444559"
        property string colorOnSecondaryContainerLight: "#e1e0f9"
        property string tertiaryLight: "#e8b9d4"
        property string colorOnTertiaryLight: "#46263b"
        property string tertiaryContainerLight: "#af849e"
        property string colorOnTertiaryContainerLight: "#000000"
        property string errorLight: "#ffb4ab"
        property string colorOnErrorLight: "#690005"
        property string errorContainerLight: "#93000a"
        property string colorOnErrorContainerLight: "#ffdad6"
        property string primaryFixedLight: "#e0e0ff"
        property string primaryFixedDimLight: "#bfc2ff"
        property string colorOnPrimaryFixedLight: "#11144b"
        property string colorOnPrimaryFixedVariantLight: "#3e4278"
        property string secondaryFixedLight: "#e1e0f9"
        property string secondaryFixedDimLight: "#c5c4dd"
        property string colorOnSecondaryFixedLight: "#191a2c"
        property string colorOnSecondaryFixedVariantLight: "#444559"
        property string tertiaryFixedLight: "#ffd8ed"
        property string tertiaryFixedDimLight: "#e8b9d4"
        property string colorOnTertiaryFixedLight: "#2e1125"
        property string colorOnTertiaryFixedVariantLight: "#5f3c52"

        onOutlineChanged: {
          if (Colors.ready) {
            ScriptRunner.setHyprlandOption("general:col.active_border", `rgb(${outline.replace("#", "")})`);
          }
        }
        onOutlineVariantChanged: {
          if (Colors.ready) {
            ScriptRunner.setHyprlandOption("general:col.inactive_border", `rgb(${outlineVariant.replace("#", "")})`);
          }
        }
      }

      property bool is_dark: true
      property string wallpaper: ""
      property real contrast_level: 0
    }
  }
}
