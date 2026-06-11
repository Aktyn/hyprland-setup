#!/bin/bash

set -e

# --- Helper Functions ---

is_installed() {
  local package="$1"
  case "$PKG_MANAGER" in
  pacman) pacman -Q "$package" >/dev/null 2>&1 ;;
  apt) dpkg -l "$package" 2>/dev/null | grep -q "^ii" ;;
  dnf) rpm -q "$package" >/dev/null 2>&1 ;;
  zypper) rpm -q "$package" >/dev/null 2>&1 ;;
  *) return 1 ;;
  esac
}

map_package() {
  local package="$1"
  case "$PKG_MANAGER" in
  apt)
    case "$package" in
    base-devel) echo "build-essential" ;;
    python) echo "python3" ;;
    python-pillow) echo "python3-pillow" ;;
    qt5-wayland) echo "qtwayland5" ;;
    qt6-wayland) echo "qt6-wayland" ;;
    qt5-multimedia) echo "libqt5multimedia5" ;;
    qt6-multimedia) echo "libqt6multimedia6" ;;
    qt5-svg) echo "libqt5svg5" ;;
    qt6-svg) echo "libqt6svg6" ;;
    qt5-declarative) echo "qml-module-qtquick2" ;;
    qt5-graphicaleffects) echo "qml-module-qtgraphicaleffects" ;;
    libdbusmenu-gtk3) echo "libdbusmenu-gtk3-dev" ;;
    gnome-themes-extra) echo "gnome-themes-standard" ;;
    plasma-activities) echo "libkf5activities5" ;;
    polkit-kde-agent) echo "polkit-kde-agent-1" ;;
    *) echo "$package" ;;
    esac
    ;;
  dnf)
    case "$package" in
    base-devel) echo "@development-tools" ;;
    python) echo "python3" ;;
    python-pillow) echo "python3-pillow" ;;
    qt5-multimedia) echo "qt5-qtmultimedia" ;;
    qt6-multimedia) echo "qt6-qtmultimedia" ;;
    libdbusmenu-gtk3) echo "libdbusmenu-gtk3" ;;
    *) echo "$package" ;;
    esac
    ;;
  *) echo "$package" ;;
  esac
}

install_package() {
  local package=$(map_package "$1")
  if ! is_installed "$package"; then
    echo "Installing $package"
    case "$PKG_MANAGER" in
    pacman) sudo pacman -S --needed --noconfirm "$package" ;;
    apt) sudo apt-get update && sudo apt-get install -y "$package" ;;
    dnf) sudo dnf install -y "$package" ;;
    zypper) sudo zypper install -y "$package" ;;
    *) echo "Unknown package manager. Please install $package manually." ;;
    esac
  fi
}

install_aur_package() {
  local package="$1"
  if [ "$PKG_MANAGER" == "pacman" ]; then
    if ! is_installed "$package"; then
      echo "Installing $package from AUR"
      if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm "$package"
      elif command -v paru >/dev/null 2>&1; then
        paru -S --needed --noconfirm "$package"
      else
        echo "AUR helper not found. Please install $package manually."
        return 1
      fi
    fi
  else
    echo "Searching for $package in standard repositories..."
    # Don't let failure of an AUR-equivalent stop the script on non-Arch
    install_package "$package" || echo "Warning: $package not found. You might need to install it manually."
  fi
}

check_battery_level() {
  if ! command -v upower >/dev/null 2>&1; then
    echo 100
    return
  fi
  local devices=$(upower --enumerate | grep battery)
  local lowest_percentage=100

  for device in $devices; do
    local percentage=$(upower -i "$device" | grep percentage | awk '{print $2}' | sed 's/%//g')
    if [ -n "$percentage" ]; then
      if [ "$percentage" -lt "$lowest_percentage" ]; then
        lowest_percentage="$percentage"
      fi
    fi
  done

  echo "$lowest_percentage"
}

# --- Detect Package Manager ---
if command -v pacman >/dev/null 2>&1; then
  PKG_MANAGER="pacman"
elif command -v apt-get >/dev/null 2>&1; then
  PKG_MANAGER="apt"
elif command -v dnf >/dev/null 2>&1; then
  PKG_MANAGER="dnf"
elif command -v zypper >/dev/null 2>&1; then
  PKG_MANAGER="zypper"
else
  echo "Unsupported package manager. This script supports pacman, apt, dnf, and zypper."
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

curr=$(realpath "$(dirname "$0")")

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
if [ "$PKG_MANAGER" == "pacman" ]; then
  install_package pacman-contrib
fi

install_package kate
install_package blueman
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
install_package ffmpegthumbnailer
install_package mpv
install_package gnome-system-monitor
install_package kitty
install_package fish
install_package sddm

if [ "$PKG_MANAGER" == "pacman" ]; then
  if ! command -v yay >/dev/null 2>&1 && ! command -v paru >/dev/null 2>&1; then
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
fi

if ! command -v warp-terminal >/dev/null 2>&1; then
  install_aur_package warp-terminal-bin
fi

install_aur_package konsole # Used in Dolphin as integrated terminal
install_aur_package yt-dlp

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
install_package tesseract-data-eng
install_package cava
install_aur_package playerctl
install_aur_package libdbusmenu-gtk3
install_package pavucontrol
install_package gwenview
install_package imagemagick

install_aur_package quickshell
install_aur_package ttf-material-icons
install_aur_package ttf-material-symbols-variable
install_aur_package ttf-jetbrains-mono-nerd
install_aur_package ttf-readex-pro
install_aur_package ttf-rubik-vf
install_aur_package ttf-twemoji

# Python packages
install_package python-pillow
install_aur_package python-materialyoucolor
install_aur_package adw-gtk-theme

required_dirs=("defaults" "quickshell" "sddm")
missing_dirs=()

for dir in "${required_dirs[@]}"; do
  if [ ! -d "$curr/$dir" ]; then
    missing_dirs+=("$dir")
  fi
done

repository_url="https://github.com/Aktyn/hyprland-setup.git"

if [ ${#missing_dirs[@]} -gt 0 ]; then
  echo "Missing required directories: ${missing_dirs[*]}"
  echo "Cloning Aktyn/hyprland-setup repository to temporary directory..."

  clone_temp_dir=$(mktemp -d)
  trap 'rm -rf $clone_temp_dir' EXIT

  git clone $repository_url "$clone_temp_dir"

  curr="$clone_temp_dir"

  echo "Repository cloned successfully. Using cloned files for setup."
fi

echo "Copying hyprland config files"
mkdir -p ~/.config/hypr/
shopt -s dotglob
for f in "$curr"/defaults/hypr/*; do
  fname=$(basename "$f")
  if [[ ("$fname" == "custom.conf" && -f ~/.config/hypr/custom.conf) || ("$fname" == "custom.lua" && -f ~/.config/hypr/custom.lua) ]]; then
    echo "Skipping existing $fname"
  else
    cp --recursive "$f" ~/.config/hypr/
  fi
done
shopt -u dotglob

echo "Copying mpv config files"
mkdir -p ~/.config/mpv/
cp --recursive "$curr/defaults/mpv/." ~/.config/mpv/

echo "Copying kitty config files"
mkdir -p ~/.config/kitty/
cp --recursive "$curr/defaults/kitty/." ~/.config/kitty/

echo "Copying btop config files"
mkdir -p ~/.config/btop/
cp --recursive "$curr/defaults/btop/." ~/.config/btop/

echo "Copying fish config files"
mkdir -p ~/.config/fish/
cp --recursive "$curr/defaults/fish/." ~/.config/fish/

# Add fish to system shells
FISH_PATH=$(command -v fish)
if [ -n "$FISH_PATH" ]; then
  if ! grep -qxF "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" | sudo tee -a /etc/shells
  fi

  # Set fish as a system-wide default shell
  current_shell=$(getent passwd "$USER" | cut -d: -f7)
  if [ "$current_shell" != "$FISH_PATH" ]; then
    echo "Changing default shell to $FISH_PATH for user $USER"
    chsh -s "$FISH_PATH"
  else
    echo "Default shell is already $FISH_PATH; skipping chsh"
  fi
fi

echo "Installing Vimix-cursors"
temp_cursor_dir=$(mktemp -d)
trap 'rm -rf $temp_cursor_dir' EXIT
git clone https://github.com/vinceliuice/Vimix-cursors.git "$temp_cursor_dir"
cd "$temp_cursor_dir"
sudo ./install.sh
cd "$curr"

echo "Copying Vimix theme"
mkdir -p ~/.local/share/icons
cp --recursive "$curr/defaults/icons/." ~/.local/share/icons/

# Configure some defaults
xdg-mime default org.kde.kate.desktop text/plain
xdg-mime default org.kde.kate.desktop application/json
xdg-mime default org.kde.gwenview.desktop image/png
xdg-mime default org.kde.gwenview.desktop image/jpg
xdg-mime default org.kde.gwenview.desktop image/jpeg
xdg-mime default org.kde.gwenview.desktop image/gif
xdg-mime default org.kde.gwenview.desktop image/bmp
xdg-mime default org.kde.gwenview.desktop image/webp
xdg-mime default org.kde.gwenview.desktop image/tif
xdg-mime default org.kde.gwenview.desktop image/tiff
xdg-mime default org.kde.gwenview.desktop image/svg

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>&1 || true
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>&1 || true
gsettings set org.gnome.desktop.interface cursor-theme 'Vimix-cursors'
plasma-apply-desktoptheme breeze-dark 2>&1 || true
plasma-apply-cursortheme Vimix-cursors 2>&1 || true

echo "Copying quickshell config files"
aktyn_shell_dir="$HOME/.config/quickshell/aktyn"
mkdir -p "$aktyn_shell_dir"
cp --recursive "$curr/quickshell/." "$aktyn_shell_dir/"
git ls-remote $repository_url HEAD | awk '{printf $1}' > "$aktyn_shell_dir/COMMIT.txt" # Copy version file for auto-update checks

killall qs >/dev/null 2>&1 || true
killall quickshell >/dev/null 2>&1 || true
sleep 1
hyprctl reload >/dev/null 2>&1 || true
nohup qs -c aktyn >/dev/null 2>&1 &

"$curr"/sddm/setup.sh

echo "Setup complete. System restart is recommended."
echo ""

hyprland --verify-config >/dev/null 2>&1 || echo "Warning: Hyprland configuration has issues. Please check your config files."
sleep 3
hyprctl reload >/dev/null 2>&1 || true
