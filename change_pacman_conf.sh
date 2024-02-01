#!/bin/bash

source ./SETTINGS

# Define the mount point and the Samba share URL
MOUNT_POINT="/opt/archlinux"
SMB_SHARE=${ARCHLINUX_REPO}

# Create the mount point directory if it doesn't exist
if [ ! -d "$MOUNT_POINT" ]; then
    sudo mkdir -p "$MOUNT_POINT"
fi

# Unmount the mount point if it's already mounted
if mountpoint -q "$MOUNT_POINT"; then
    echo "Unmounting existing mount at $MOUNT_POINT"
    sudo umount "$MOUNT_POINT"
fi

# Mount the Samba share
sudo mount "$SMB_SHARE" "$MOUNT_POINT" 

# Backup the existing pacman.conf
sudo cp /etc/pacman.conf /etc/pacman.conf.bak

# Modify the pacman configuration
sudo sed -i '/^\[core\]$/,/^\[extra\]$/ s|^Include = /etc/pacman.d/mirrorlist|#Include = /etc/pacman.d/mirrorlist|' /etc/pacman.conf
sudo sed -i '/^\[extra\]$/,/^\[multilib\]$/ s|^Include = /etc/pacman.d/mirrorlist|#Include = /etc/pacman.d/mirrorlist|' /etc/pacman.conf

# Add local repository paths for core, extra, and multilib
sudo sed -i '/^\[core\]$/a\\nServer = file://'"$MOUNT_POINT/core/os/x86_64"'' /etc/pacman.conf
sudo sed -i '/^\[extra\]$/a\\nServer = file://'"$MOUNT_POINT/extra/os/x86_64"'' /etc/pacman.conf
sudo sed -i '/^\[multilib\]$/a\\nServer = file://'"$MOUNT_POINT/multilib/os/x86_64"'' /etc/pacman.conf

# Refresh pacman databases
sudo pacman -Syy
