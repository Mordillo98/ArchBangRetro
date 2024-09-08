#!/bin/bash

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# NEED TO BE RAN WITH ADMIN PRIVILEGES
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

if [ "$EUID" -ne 0 ]
  then
    printf "\n${CYAN}This script needs to be ran with admin privileges to execute properly.\n\n${NC}"
  exit
fi

# Check if the SETTINGS file exists
if [ -e "./SETTINGS" ]; then
    source "./SETTINGS"
else
    echo "Error: SETTINGS file not found. Please make sure the file exists."
    exit 1
fi

   # custom to have it look like archbang 2012 
   cp grub_old/grub /etc/default/
   cp grub_old/10_linux /etc/grub.d/
   mkdir -p /boot/grub/fonts
   cp grub_old/VGA_8x16.pf2 /boot/grub/fonts/

if [ ${FIRMWARE} = "BIOS" ]; then
   
   # custom to have it look like archbang 2012 
   rm /etc/grub.d/60_memtest86+

   grub-install --target=i386-pc ${DRIVE}
else

   # custom to have it look like archbang 2012 
   rm /etc/grub.d/30_uefi-firmware

   grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ArchBang
fi

grub-mkconfig -o /boot/grub/grub.cfg

