#!/usr/bin/env bash

ACTIVE_ID=$(hyprctl activeworkspace -j | jq -r .id)

# Handle special workspaces (usually negative IDs)
if [ "$ACTIVE_ID" -lt 0 ]; then
    GROUP=0
else
    GROUP=$(( ($ACTIVE_ID - 1) / 10 ))
fi

TARGET=$(( $GROUP * 10 + $2 ))

case "$1" in
    "workspace")
        hyprctl dispatch "hl.dsp.focus({ workspace = '$TARGET' })"
        ;;
    "movetoworkspacesilent")
        hyprctl dispatch "hl.dsp.window.move({ workspace = '$TARGET', follow = false })"
        ;;
    *)
        # Fallback for other dispatchers
        hyprctl dispatch "hl.dsp.$1({ workspace = '$TARGET' })"
        ;;
esac
