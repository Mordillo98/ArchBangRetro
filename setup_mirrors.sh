#!/bin/bash
# This script runs once as called from the XDG autostart desktop file,
# then disables that desktop file so it does not run again.

# Get public IP and determine the country code.
IP=$(curl -s ifconfig.me)
REFLECTOR_COUNTRY=$(curl -s "https://ipinfo.io/${IP}/country")

# Terminal color definitions.
YELLOW='\033[1;33m'
NC='\033[0m'

printf "\n${YELLOW}Setting up best 5 HTTPS mirrors from ${REFLECTOR_COUNTRY}...\n\n${NC}"

# Update mirrorlist using reflector.
sudo reflector --country "${REFLECTOR_COUNTRY}" --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Refresh package database.
sudo pacman -Sy > /dev/null
sudo pacman-key --init && sudo pacman-key --populate archlinux

# Disable future autostart by modifying the desktop file.
DESKTOP_FILE="$HOME/.config/autostart/setup_mirrors.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    # Setting Hidden=true disables the desktop file per XDG spec.
    if grep -q "^Hidden=" "$DESKTOP_FILE"; then
        sed -i 's/^Hidden=.*/Hidden=true/' "$DESKTOP_FILE"
    else
        echo "Hidden=true" >> "$DESKTOP_FILE"
    fi
fi

exit 0

