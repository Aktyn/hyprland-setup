#!/bin/bash

is_installed() {
  local package="$1"
  pacman -Q "$package" > /dev/null 2>&1
}

install_package() {
  if ! is_installed "$1"; then
    echo "Installing $1"
    sudo pacman -S --needed --noconfirm $1
  else
    echo "$1 is already installed"
  fi
}

curr=$(dirname $0)
temp_dir="$curr/temp"

cd $curr

install_package git
install_package base-devel
install_package kate
install_package blueman

#TODO: skip if yay is already insalled (which yay)
mkdir -p "$temp_dir"
cd "$temp_dir"
git clone https://aur.archlinux.org/yay.git
cd "$temp_dir/yay"
pwd
makepkg -si
rm -rf "$curr/temp"

cd $curr

# ~/.config/hypr/hyprland.conf