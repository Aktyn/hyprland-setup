#!/bin/bash

set -e

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

battery_level=$(check_battery_level)
if [ "$battery_level" -lt 20 ]; then
    echo "Battery level is too low ($battery_level%). Please charge your device and try again."
    exit 1
fi

curr=$(realpath $(dirname $0))

echo "######################################################################"
echo "### Hyprland should be already installed on your system            ###"
echo "### This script will override your existing hyprland configuration ###"
echo "### SDDM with custom theme will be used as login manager           ###"
echo "### Confirm that you want to proceed by typing your sudo password  ###"
echo "######################################################################"
echo ""
sudo -v

install_package git
install_package python
install_package base-devel
install_package kate
install_package blueman # bluetooth gui
install_package btop
install_package curl
install_package xclip
install_package cliphist
install_package wl-clipboard
install_package gnome-keyring
install_package gnome-themes-extra
install_package plasma-nm
install_package plasma-activities
install_package polkit-kde-agent
install_package systemsettings
install_package nwg-look
install_package kdialog
install_package dolphin
install_package gnome-system-monitor
install_package kitty
install_package fish

if ! which yay > /dev/null 2>&1; then
    echo "Installing yay"
    temp_dir="$curr/temp"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    rm -rf ./yay
    git clone https://aur.archlinux.org/yay.git
    cd ./yay
    makepkg -si --noconfirm
    cd "$curr"
    rm -rf "$temp_dir"
fi

install_aur_package warp-terminal-bin

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

install_package hyprsunset
install_package hypridle
install_package hyprlock
install_package hyprpicker
install_package hyprshot
install_package grim
install_package slurp
install_package tesseract
install_package cava
install_aur_package playerctl
install_aur_package libdbusmenu-gtk3
install_package pavucontrol
install_package gwenview
install_aur_package imagemagick

install_aur_package quickshell
install_aur_package ttf-material-icons
install_aur_package ttf-material-symbols-variable
install_aur_package ttf-jetbrains-mono-nerd
install_aur_package ttf-readex-pro
install_aur_package ttf-rubik-vf

# Python packages
install_package python-pillow
install_aur_package python-materialyoucolor-git # Try again couple of times if this fails

required_dirs=("defaults" "quickshell" "sddm")
missing_dirs=()

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$curr/$dir" ]; then
        missing_dirs+=("$dir")
    fi
done

if [ ${#missing_dirs[@]} -gt 0 ]; then
    echo "Missing required directories: ${missing_dirs[*]}"
    echo "Cloning Aktyn/hyprland-setup repository to temporary directory..."
    
    clone_temp_dir=$(mktemp -d)
    trap "rm -rf $clone_temp_dir" EXIT
    
    git clone https://github.com/Aktyn/hyprland-setup.git "$clone_temp_dir"
    
    curr="$clone_temp_dir"
    
    echo "Repository cloned successfully. Using cloned files for setup."
fi

echo "Copying hyprland config files"
mkdir -p ~/.config/hypr/
for f in "$curr"/defaults/hypr/*; do
    if [[ "$(basename "$f")" == "custom.conf" && -f ~/.config/hypr/custom.conf ]]; then
        echo "Skipping existing custom.conf"
    else
        cp -r "$f" ~/.config/hypr/
    fi
done

echo "Copying kitty config files with fish set as shell"
mkdir -p ~/.config/kitty/
cp -r "$curr/defaults/kitty/." ~/.config/kitty/

# Add fish to system shells
if ! grep -qxF '/usr/bin/fish' /etc/shells; then
    echo /usr/bin/fish | sudo tee -a /etc/shells
fi

# Set fish as a system-wide default shell (only if not already)
# Determine current user's login shell and switch only if different.
current_shell=$(getent passwd "$USER" | cut -d: -f7)
if [ "$current_shell" != "/usr/bin/fish" ]; then
    echo "Changing default shell to /usr/bin/fish for user $USER"
    chsh -s /usr/bin/fish
else
    echo "Default shell is already /usr/bin/fish; skipping chsh"
fi

# TODO: fix cursors installation
# echo "Installing Vimix-cursors"
# temp_cursor_dir=$(mktemp -d)
# trap "rm -rf $temp_cursor_dir" EXIT
# git clone https://github.com/vinceliuice/Vimix-cursors.git "$temp_cursor_dir"
# cd "$temp_cursor_dir"
# "$temp_cursor_dir"/install.sh

cd "$curr"

echo "Copying quickshell config files"
mkdir -p ~/.config/quickshell/aktyn
cp -r "$curr/quickshell/." ~/.config/quickshell/aktyn/

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>&1 || true
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark' 2>&1 || true

killall qs > /dev/null 2>&1 || true
hyprctl reload > /dev/null 2>&1 || true
qs -c aktyn > /dev/null 2>&1 &

"$curr"/sddm/setup.sh

echo "Setup complete. System restart is recommended."
