#!/bin/bash

# This script runs install.sh every time file inside defaults/ directory is modifed

is_installed() {
    local package="$1"
    pacman -Q "$package" > /dev/null 2>&1
}

if ! is_installed inotify-tools; then
    echo "Installing inotify-tools"
    sudo pacman -S --needed --noconfirm inotify-tools
fi

./install.sh
while inotifywait -r -qq -e modify install.sh defaults/** sddm/**; do ./install.sh; done