#!/bin/bash

# This script will configure SDDM custom theme

disable_service() {
    local service_name="$1"
    if systemctl is-active --quiet "$service_name"; then
        sudo systemctl disable "$service_name"
        sudo systemctl stop "$service_name"
    fi
}

if which gdm > /dev/null 2>&1; then
    echo "GDM is installed. Disabling it to avoid conflicts with SDDM."
    disable_service gdm.service
fi

if which lightdm > /dev/null 2>&1; then
    echo "LightDM is installed. Disabling it to avoid conflicts with SDDM."
    disable_service lightdm.service
fi

if ! which sddm > /dev/null 2>&1; then
    echo "SDDM is not installed. Installing it now."
    
    sudo pacman -S --needed --noconfirm sddm
    sudo systemctl enable sddm.service
    sudo systemctl start sddm.service
    
    echo "SDDM installed and enabled."
fi

if ! which sddm > /dev/null 2>&1; then
    echo "SDDM installation failed. Please install it manually."
    exit 1
fi

echo "Setting up SDDM theme."
sudo install -d -m 0755 /etc/sddm.conf.d
sudo cp -f ./sddm/sddm.conf /etc/sddm.conf.d/aktyn.conf
sudo mkdir -p /usr/share/sddm/themes/aktyn
sudo cp -r -f ./sddm/theme /usr/share/sddm/themes/aktyn