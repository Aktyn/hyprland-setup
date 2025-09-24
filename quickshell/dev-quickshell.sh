#!/bin/bash

# This script watches for changes in quickshell files and restarts qs

set -e

restart_qs() {
    killall qs > /dev/null 2>&1 || true
    killall kde6 > /dev/null 2>&1 || true
    qs -p . &
}

is_installed() {
    local package="$1"
    pacman -Q "$package" > /dev/null 2>&1
}

if ! is_installed inotify-tools; then
    echo "Installing inotify-tools"
    sudo pacman -S --needed --noconfirm inotify-tools
fi

curr=$(dirname $0)

restart_qs
while inotifywait -r -qq -e modify $curr/**; do restart_qs; done