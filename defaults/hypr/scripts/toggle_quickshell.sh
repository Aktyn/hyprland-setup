#!/usr/bin/env bash

if pgrep -x "qs" > /dev/null; then
    killall ags agsv1 gjs qs quickshell
else
    qs -c aktyn &
    (
        sleep 5
        hyprctl reload
    ) &
fi
