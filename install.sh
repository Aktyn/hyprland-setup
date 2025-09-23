#!/bin/bash

set -e

#TODO: check repo version and ask user if they want to update if there is a newer version

is_installed() {
    local package="$1"
    pacman -Q "$package" > /dev/null 2>&1
}

install_package() {
    if ! is_installed "$1"; then
        echo "Installing $1"
        sudo pacman -S --needed --noconfirm $1
    fi
}

is_aur_installed() {
    local package="$1"
    pacman -Q "$package" > /dev/null 2>&1
}

install_aur_package() {
    if ! is_aur_installed "$1"; then
        echo "Installing $1 from aur"
        yay -S --needed --noconfirm $1
    fi
}

check_battery_level() {
    local devices=$(upower --enumerate | grep battery)
    local lowest_percentage=100

    for device in $devices; do
        local percentage=$(upower -i $device | grep percentage | awk '{print $2}' | sed 's/%//g')
        if [ -n "$percentage" ]; then
            if [ "$percentage" -lt $lowest_percentage ]; then
                lowest_percentage="$percentage"
            fi
        fi
    done

    echo "$lowest_percentage"
}

# Prevent from running on non-arch based systems
if ! [ -f /etc/arch-release ]; then
    echo "This script is intended to run on Arch-based systems only."
    exit 1
fi

# Prevent from running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please do not run this script as root."
    exit 1
fi

curr=$(dirname $0)
temp_dir="$curr/temp"

echo "######################################################################"
echo "### Hyprland should be already installed on your system            ###"
echo "### This script will override your existing hyprland configuration ###"
echo "### Login screen will be replaced with SDDM and its custom theme   ###"
echo "### Confirm that you want to proceed by typing your sudo password  ###"
echo "######################################################################"
echo ""
sudo -v

battery_level=$(check_battery_level)
if [ "$battery_level" -lt 20 ]; then
    echo "Battery level is too low ($battery_level%). Please charge your device and try again."
    exit 1
fi

install_package git
install_package base-devel
install_package kate
install_package blueman # bluetooth gui

if ! which yay > /dev/null 2>&1; then
    echo "Installing yay"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    git clone https://aur.archlinux.org/yay.git
    cd "$temp_dir/yay"
    pwd
    makepkg -si
    rm -rf "$curr/temp"
fi

if ! which yay > /dev/null 2>&1; then
  install_aur_package warp-terminal-bin
fi

# Quickshell setup
install_package qt5-wayland
install_package qt6-wayland
install_package qt5-multimedia
install_package qt6-multimedia
install_package qt5-imageformats
install_package qt6-imageformats
install_package qt5-svg
install_package qt6-svg
install_package qt5-declarative
install_package qt5-graphicaleffects
install_aur_package quickshell

cd $curr
#TODO: clone repository if required files are not found locally

echo "Copying hyprland config files"
cp -r ./defaults/. ~/.config/hypr/

echo "Copying quickshell config files"
mkdir -p ~/.config/quickshell/aktyn
cp -r ./quickshell/* ~/.config/quickshell/aktyn/

killall qs > /dev/null 2>&1 || true
hyprctl reload > /dev/null 2>&1 || true
qs -c aktyn > /dev/null 2>&1 &

$curr/sddm/setup.sh

echo "Setup complete. System restart is recommended."