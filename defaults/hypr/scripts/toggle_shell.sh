#!/usr/bin/env bash

shell="$HOME/.local/bin/aktyn-shell"

if pgrep -x "aktyn-shell" > /dev/null; then
    "$shell" --toggle
else
    "$shell" &
    (
        sleep 5
        hyprctl reload
    ) &
fi
