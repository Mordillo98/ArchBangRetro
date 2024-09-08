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

# +-+-+-
# MAIN 
# +-+-+-

SOURCE_DIR=$1
DEST_DIR=$2

mkdir -p ${DEST_DIR}
cp -R /mnt${SOURCE_DIR}/HOOKS/* ${DEST_DIR}

   # +-+-+-+-
   # PCMANFM
   # +-+-+-+-

   printf "cp ${SOURCE_DIR}/applications/pcmanfm.desktop /usr/share/applications/" >> /mnt/etc/pacman.d/hooks/scripts/pcmanfm_install.sh

   # +-+-+-+-+-
   # CBATTICON
   # +-+-+-+-+-

   printf "cp ${SOURCE_DIR}/applications/batti.desktop /usr/share/applications/" >> /mnt/etc/pacman.d/hooks/scripts/cbatticon_install.sh

   printf "rm /usr/share/applications/batti.desktop" >> /mnt/etc/pacman.d/hooks/scripts/cbatticon_uninstall.sh

   # +-+-+-+-+
   # SHOTWELL
   # +-+-+-+-+

   printf "cp ${SOURCE_DIR}/applications/org.gnome.Shotwell.desktop /usr/share/applications/" >> /mnt/etc/pacman.d/hooks/scripts/shotwell_install.sh

   # +-+-+-+-+-+
   # PARCELLITE
   # +-+-+-+-+-+

   printf "cp ${SOURCE_DIR}/applications/parcellite.desktop /usr/share/applications/" >> /mnt/etc/pacman.d/hooks/scripts/parcellite_install.sh

   # +-+-+-+-+
   # CATFISH
   # +-+-+-+-+

   printf "cp ${SOURCE_DIR}/applications/org.xfce.Catfish.desktop /usr/share/applications/" >> /mnt/etc/pacman.d/hooks/scripts/catfish_install.sh

   # +-+-+-+-+-+
   # LIBFM-GTK2
   # +-+-+-+-+-+

   printf "cp ${SOURCE_DIR}/applications/libfm-pref-apps.desktop /usr/share/applications/" >> /mnt/etc/pacman.d/hooks/scripts/libfm-gtk2_install.sh

   # +-+-+-+-+-+-+-+-+
   # GNOME-ICON-THEME
   # +-+-+-+-+-+-+-+-+

   printf "cp ${SOURCE_DIR}/icons/applications-accessories.png /usr/share/icons/gnome/48x48/categories/" >> /mnt/etc/pacman.d/hooks/scripts/gnome-icon-theme_install.sh

   # +-+-+-+-+-+
   # LXTERMINAL
   # +-+-+-+-+-+

   printf "cp ${SOURCE_DIR}/applications/lxterminal.desktop /usr/share/applications/" >> /mnt/etc/pacman.d/hooks/scripts/lxterminal_install.sh


   # +-+-+-+-+-+-+-+
   # FLAT-REMIX-GTK
   # +-+-+-+-+-+-+-+

   
   
   # +-+-+-+-
   # XFBURN
   # +-+-+-+-

   printf "cp ${SOURCE_DIR}/applications/xfburn.desktop /usr/share/applications/" >> /mnt/etc/pacman.d/hooks/scripts/xfburn_install.sh


   # +-+-+-+-+-+-+
   # EPDFVIEW-GIT
   # +-+-+-+-+-+-+

   printf "cp ${SOURCE_DIR}/applications/epdfview.desktop /usr/share/applications/" >> /mnt/etc/pacman.d/hooks/scripts/epdfview-git_install.sh
   
   # +-+-+-+-+-+-+-+-+-+-+-+
   # NETWORK-MANAGER-APPLET
   # +-+-+-+-+-+-+-+-+-+-+-+

   printf "cp ${SOURCE_DIR}/applications/nm-connection-editor.desktop /usr/share/applications/\n" >> /mnt/etc/pacman.d/hooks/scripts/network-manager-applet_install.sh
   printf "sed -i 's/Exec=nm-applet/Exec=nm-applet --sm-disable/g' /etc/xdg/autostart/nm-applet.desktop\n" >> /mnt/etc/pacman.d/hooks/scripts/network-manager-applet_install.sh
   printf "systemctl enable NetworkManager.service" >> /mnt/etc/pacman.d/hooks/scripts/network-manager-applet_install.sh

   # +-+-+-+-+-+-+-+-+-+
   # GNOME-DISK-UTILITY
   # +-+-+-+-+-+-+-+-+-+

   printf "cp ${SOURCE_DIR}/applications/org.gnome.DiskUtility.desktop /usr/share/applications/" >> /mnt/etc/pacman.d/hooks/scripts/gnome-disk-utility_install.sh

   # +-+-+-
   # TINT2
   # +-+-+-

   printf "cp ${SOURCE_DIR}/applications/tint2conf.desktop /usr/share/applications/" >> /mnt/etc/pacman.d/hooks/scripts/tint2conf_install.sh

   printf "rm /usr/share/applications/tint2conf.desktop" >> /mnt/etc/pacman.d/hooks/scripts/tint2_uninstall.sh

   # +-+-+-+-+-+-+-
   # HARDINFO-GIT
   # +-+-+-+-+-+-+-

   printf "cp ${SOURCE_DIR}/applications/hardinfo.desktop /usr/share/applications/" >> /mnt/etc/pacman.d/hooks/scripts/hardinfo-git_install.sh
   
   # +-+-+-+-+-+
   # VOLUMEICON
   # +-+-+-+-+-+

   printf "cp ${SOURCE_DIR}/applications/volumeicon.desktop /etc/xdg/autostart/\n" >> /mnt/etc/pacman.d/hooks/scripts/volumeicon_install.sh

   printf "rm /etc/xdg/autostart/volumeicon.desktop" >> /mnt/etc/pacman.d/hooks/scripts/volumeicon_uninstall.sh

   # +-+-+-+-+-+-+-+-+-+
   # XFCE4-NOTIFYD
   # +-+-+-+-+-+-+-+-+-+


# cp -R /mnt/etc/pacman.d/hooks/* ${DEST_DIR} 
