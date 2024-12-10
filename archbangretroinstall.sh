#!/bin/bash

# set -e  # Script must stop if there is an error.
# set -x

# +-+-+-+-+
# SETTINGS
# +-+-+-+-+

# Reads the SETTINGS file to define global variables.

# Check if the SETTINGS file exists
if [ -e "./SETTINGS" ]; then
    source "./SETTINGS"
else
    echo "Error: SETTINGS file not found. Please make sure the file exists."
    exit 1
fi

#
# FUNCTIONS
# ========
# 

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-
# YES_OR_NO (question, default answer)
# =========
#
# Ask a yes or no question.
# $1: Question
# $2: Default answer (Y or N)
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-

function yes_or_no {

   # First, the function takes two arguments: a question to ask and a default answer (which is assumed to be "no" if not provided).
   QUESTION=$1
   DEFAULT_ANSWER=$2

   # If a default answer is provided, convert it to uppercase using the ${VAR^^} syntax.
   DEFAULT_ANSWER=${DEFAULT_ANSWER^^}
  
   # Initialize a variable to store the user's answer.
   Y_N_ANSWER=""
  
   # Use a loop to repeatedly prompt the user for a yes or no answer until a valid answer is given.
   until [ "$Y_N_ANSWER" == Y ] || [ "$Y_N_ANSWER" == N ]; do

      # Initialize a variable to store the user's input.
      yn=""

      # Ask the question and provide a default answer (if one was specified).
      # Use the ${WHITE} and ${NC} variables (defined under the SETTINGS file) to set the text color.
      # Read the user's input using the read command.
      printf "${QUESTION}"
      if [ ${DEFAULT_ANSWER} == "Y" ]
        then
	        printf " ${WHITE}[Y/n]: ${NC}"
          read yn
        else
	        printf " ${WHITE}[y/N]: ${NC}"
          read yn
      fi

      # If the user simply presses enter (i.e., no input is provided), use the default answer.
      if [ "$yn" == "" ]
        then Y_N_ANSWER=$DEFAULT_ANSWER
      fi

      # Use a case statement to set the Y_N_ANSWER variable based on the user's input.
      case $yn in
         [Yy]*) Y_N_ANSWER="Y" ;;
         [Nn]*) Y_N_ANSWER="N" ;;
      esac

   done

   # Finally, convert the answer to uppercase (using the ${VAR^^} syntax) and return it.
   Y_N_ANSWER=${Y_N_ANSWER^^}

}


# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
#
# COUNTSLEEP (message, secs delay)
#
# This function is used to pause the 
# installation at start with a message 
# for x seconds.
#
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

function countsleep {
  
  MESSAGE=$1
  END=$2
  TIME_REMAINING=$((END+1))
  
  for ((i = 1; i <= ${END}; i++)); do
    TIME_REMAINING=$((TIME_REMAINING-1))
    printf "${YELLOW}${MESSAGE}${WHITE}${TIME_REMAINING} \r"
    sleep 1
  done	

  printf "${NC}\n\n"

}

#
# MAIN SCRIPT
# ===========	
# 


# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# NEED TO BE RAN WITH ADMIN PRIVILEGES
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

if [ "$EUID" -ne 0 ]
  then
    printf "\n${CYAN}This script needs to be ran with admin privileges to execute properly.\n\n${NC}"
  exit
fi


# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# ENABLE ALL OUTPUTS TO BE SENT
# TO LOG.OUT DURING THE SCRIPT
# FOR DEBUGGING USAGE.
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

echo ""
yes_or_no "Would you like to have the outputs into log.out?" "n"

if [ "$Y_N_ANSWER" == "Y" ]; then
  # Create a temporary named pipe (FIFO)
  TEMP_FIFO=$(mktemp -u)
  mkfifo "$TEMP_FIFO"
  exec 3>&1 4>&2
  
  # Start a background process to read from the pipe and write to both the log file and stdout
  tee log.out < "$TEMP_FIFO" &
  TEE_PID=$!
  
  # Redirect stdout and stderr to the named pipe
  exec > "$TEMP_FIFO" 2>&1
  
  # Ensure cleanup on script exit
  trap 'exec 1>&3 2>&4; rm -f "$TEMP_FIFO"; if kill -0 "$TEE_PID" 2>/dev/null; then kill "$TEE_PID"; fi' EXIT
fi


# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# SHOW THE PARAMETERS ON SCREEN
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

clear
printf "\n\n${WHITE}ARCHBANG RETRO INSTALL SCRIPT\n"
printf "=============================\n\n"
printf "${CYAN}Press Control-C to Cancel\n\n"
printf "${GREEN}FIRMWARE    = ${CYAN}${FIRMWARE}\n\n"
printf "${GREEN}TIMEZONE    = ${CYAN}${TIMEZONE}\n"
printf "${GREEN}REGION      = ${CYAN}${REGION}\n"
printf "${GREEN}LANGUAGE    = ${CYAN}${LANGUAGE}\n"
printf "${GREEN}KEYMAP      = ${CYAN}${KEYMAP}\n\n"
printf "${GREEN}HOSTNAME    = ${CYAN}${HOSTNAME}\n\n"
printf "${GREEN}ARCH_USER   = ${CYAN}${ARCH_USER}\n"
printf "${GREEN}USER_PSW    = ${CYAN}${USER_PSW}\n"
printf "${GREEN}ROOT_PSW    = ${CYAN}${ROOT_PSW}\n\n"
printf "${GREEN}NVIDIA        = ${CYAN}${NVIDIA}\n"
printf "${GREEN}NVIDIA_LEGACY = ${CYAN}${NVIDIA_LEGACY}\n\n"

printf "${WHITE}*********************************************${NC}\n\n"

printf "${RED}THIS WILL DESTROY ALL CONTENT OF ${WHITE}${BCK_RED}${DRIVE^^}${NC}${RED} !!!\n\n"

printf "${GREEN}BOOT = ${CYAN}${DRIVE_PART1}\n"
printf "${GREEN}SWAP = ${CYAN}${DRIVE_PART2}\n"
printf "${GREEN}ROOT = ${CYAN}${DRIVE_PART3}\n\n"

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# COUNTDOWN WARNING
# =================
# 
# This is needed to not only warn the HD will be 
# wiped, but for the install to work on slow hardware 
# as not all the services are started when the auto-login 
# occurs on the live CD, making this script fails when 
# launched too early.
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

# countsleep "Automatic install will start in... " 30 

# Initialize the time counter and set the timeout duration
TIMEOUT=30
INTERVAL=1
TIME_ELAPSED=0
PACMAN_KEYS_DIR="/etc/pacman.d/gnupg"

# Function to check if pacman keys are initialized
are_keys_initialized() {
    if [ -d "$PACMAN_KEYS_DIR" ]; then
        pacman-key --list-keys > /dev/null 2>&1
        return $?
    else
        return 1
    fi
}

# Check if the pacman keys are already initialized
if are_keys_initialized; then
    printf "\n${WHITE}Pacman keys have been initialized.${NC}\n\n"
else
    printf "\n${YELLOW}Waiting for pacman keys to be initialized..."
    # Loop until the pacman keys are properly initialized or the timeout is reached
    while [ $TIME_ELAPSED -lt $TIMEOUT ]; do
        if are_keys_initialized; then
            printf "\n\n${WHITE}Pacman keys have been initialized.${NC}\n\n"
            break
        fi
        printf "."
        sleep $INTERVAL
        TIME_ELAPSED=$((TIME_ELAPSED + INTERVAL))
    done

    # If the loop exits without finding the keys, print the error message and exit
    if [ $TIME_ELAPSED -ge $TIMEOUT ]; then
        printf "\n\n${WHITE}Pacman keys are not initialized.\n"
	printf "Verify your network connection, and try again...${NC}\n\n"
        exit 1
    fi
fi


# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# INSTALL THE NEEDED DEPENDENCIES 
# TO RUN THIS SCRIPT FROM ARCH LIVE CD
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

printf "${CYAN}Updating archlinux's repos.\n\n${NC}"
pacman -Sy 

echo


# +-+-+-+-+-+-+-+-+-+-+-+-
# UPDATE THE SYSTEM CLOCK 
# +-+-+-+-+-+-+-+-+-+-+-+-

timedatectl set-ntp true


# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# PARTITION AND FORMAT THE DISKS
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

countsleep "Partitioning the disk will start in... " 5

cd ${CURRENT_DIR}
source ./format_hd.sh


# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# MOUNT THE NEWLY CREATED PARTITIONS
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

mount /${DRIVE_PART3} /mnt
mkdir -p /mnt/boot
mount ${DRIVE_PART1} /mnt/boot

mkdir -p /mnt/etc/pacman.d/


# +-+-+-+-+-+-+-+-+
# SETUP /ETC/FSTAB
# +-+-+-+-+-+-+-+-+

genfstab -U /mnt >> /mnt/etc/fstab

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# ARCHBANGRETRO (where the magic starts :)
#
# Copying custom files needed during 
# arch-chroot script.
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

mkdir -p /mnt${ARCHBANGRETRO_FOLDER}
cd /mnt${ARCHBANGRETRO_FOLDER}

# Download the file and compute its MD5 checksum

printf "\n${CYAN}ARCHBANGRETRO_FILE_URL = ${YELLOW}${ARCHBANGRETRO_FILE_URL}${NC}\n\n"

curl -L -o archbangretro.tar.xz "${ARCHBANGRETRO_FILE_URL}"
ACTUAL_MD5=$(md5sum "$(basename "${ARCHBANGRETRO_FILE_URL}")" | awk '{ print $1 }')

# Compare the expected and actual MD5 checksums
if [[ "${ARCHBANGRETRO_EXPECTED_MD5}" == "${ACTUAL_MD5}" ]]; then
   printf "\n${GREEN}File download successful and MD5 checksum verified${NC}\n\n"
   sleep 2
else
   printf "\n${RED}Error: MD5 checksum does not match${NC}\n\n"	
   rm "$(basename "${ARCHBANGRETRO_FILE_URL}")"
   exit 1
fi

tar -xvf $(basename "$ARCHBANGRETRO_FILE_URL")
rm -f $(basename "$ARCHBANGRETRO_FILE_URL")


# +-+-+-+-+-+
# ALPM-HOOKS
# +-+-+-+-+-+

cd ${CURRENT_DIR}
source ./pacman_hooks.sh ${ARCHBANGRETRO_FOLDER} "/mnt/etc/pacman.d/hooks/"

rmdir /etc/pacman.d/hooks
ln -s /mnt/etc/pacman.d/hooks /etc/pacman.d/


# +-+-+-+-+-+-+-+-
# ENABLE MULTILIB
# +-+-+-+-+-+-+-+-

printf "\n${WHITE}Enabling [MULTILIB] repo...\n\n${NC}" 

sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf


# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# ADD ARCHBANGRETRO LOCAL REPO
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+

cd ${CURRENT_DIR}
source ./aurbin_repo.sh


# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# ENABLE BEST MIRRORS FOR PACMAN
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

# Get your public IP and country
IP=$(curl -s ifconfig.me)
REFLECTOR_COUNTRY=$(curl -s https://ipinfo.io/${IP}/country)

printf "${YELLOW}Setting up best 5 https mirrors from ${REFLECTOR_COUNTRY} for this install.\n\n${NC}" 

reflector --country "${REFLECTOR_COUNTRY}" --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

pacman -Sy > /dev/null

# Define the file path
FILE_PATH="/etc/pacman.conf"

# Backup the original file before modifying
cp "$FILE_PATH" "${FILE_PATH}.bak"

# Uncomment the line and set the value for ParallelDownloads
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' "$FILE_PATH"

printf "${CYAN}PACMAN parallel downloads is now enabled.\n\n${CYAN}"


# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# REMOVE UNWANTED DESKTOP FILES DURING PACMAN INSTALLS
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

cd ${CURRENT_DIR}
source ./no_desktop_files.sh


# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# BACKUP PACMAN.CONF INTO CHROOT SESSION
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

cp /etc/pacman.conf /mnt/etc/pacman.conf.bck


# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# COPYING MIRRORLIST TO NEW INSTALLATION
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/


# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# MAKING SURE CREATING THE INITRAMFS IS FAST
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

printf "${WHITE}Making sure the initramfs creation will be fast.\n\n${NC}"

# Define the new HOOKS line
NEW_HOOKS="HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)"

# Path to the mkinitcpio.conf file
MKINITCPIO_CONF="/etc/mkinitcpio.conf"

cp ${MKINITCPIO_CONF} ${MKINITCPIO_CONF}.bck

# Use sed to replace the HOOKS line
sed -i "s/^HOOKS=.*/${NEW_HOOKS}/" ${MKINITCPIO_CONF}

# Uncomment the COMPRESSION line and set it to lz4
sed -i "s/^#COMPRESSION=\"lz4\"/COMPRESSION=\"lz4\"/" ${MKINITCPIO_CONF}

CONFIG_FILE="/etc/makepkg.conf"
SEARCH_PATTERN="#MAKEFLAGS"
REPLACEMENT="MAKEFLAGS=\"-j\$(nproc)\""

cp ${CONFIG_FILE} ${CONFIG_FILE}.bck
sed -i "s|^$SEARCH_PATTERN.*|$REPLACEMENT|" "$CONFIG_FILE"

cp ${MKINITCPIO_CONF} /mnt${MKINITCPIO_CONF}
cp ${CONFIG_FILE} /mnt${CONFIG_FILE}


# +-+-+-+-+-+-+-+-+
# INSTALL PACKAGES
# +-+-+-+-+-+-+-+-+

EDITOR="vim nano"
# CATFISH_DEPENDENCIES="dbus-python"
# DEPENDENCIES="autoconf-archive hwinfo nfs-utils go gnome-themes-standard git intltool python-cairo python-gobject python-pillow libxft libxinerama gdk-pixbuf-xlib python-distutils-extra cmake cblas lapack gcc-fortran"
XORG="xorg-server xorg-xinit xorg-xkill"
OPENBOX="openbox ttf-dejavu ttf-liberation python-pyxdg"
OPENBOX_MENU="glib2 gtk2 menu-cache gnome-menus lxmenu-data"
AUR_APPS="archbangretro-wallpaper archbey batti-icons deadbeef dmenu epdfview-git fbxkb flat-remix-gtk gnome-carbonate gnome-disk-utility-3.4.1 gnome-icon-theme gnome-icon-theme-symbolic hardinfo-git httpdirfs madpablo-theme mhwd-manjaro-bin obkey-python3 oblogout-py3-git obmenu2-git openbox-menu openbox-themes python-gettext ttf-ms-win11-auto ttf-ms-win11-auto-japanese ttf-ms-win11-auto-korean ttf-ms-win11-auto-other ttf-ms-win11-auto-sea ttf-ms-win11-auto-thai ttf-ms-win11-auto-zh_cn ttf-ms-win11-auto-zh_tw yay-bin"
ARCHBANG_APPS="catfish reflector lxterminal lxappearance lxappearance-obconf lxinput leafpad gucharmap pcmanfm galculator parcellite xarchiver shotwell htop arandr obconf tint2 conky xcompmgr nitrogen scrot exo gnome-mplayer xfburn libfm-gtk2 gmrun slim packer arj cronie dialog dnsutils gnome-keyring gsimplecal gtk-engine-murrine gtk-engines inetutils jfsutils logrotate lzop memtest86+ modemmanager ntfs-3g p7zip reiserfsprogs rsync squashfs-tools syslinux tcl unrar unzip usb_modeswitch zip gvfs cbatticon xdg-utils pv nfs-utils glxinfo speech-dispatcher unclutter xdotool"
ARCHBANG_ICONS="gtk-update-icon-cache hicolor-icon-theme librsvg icon-naming-utils intltool" 
CODECS="a52dec faac faad2 jasper lame libdca libdv libmad libmpeg2 libtheora libvorbis libxv wavpack x264 xvidcore gstreamer"
SOUND="volumeicon alsa-utils pulseaudio alsa-firmware alsa-oss"
NETWORK="network-manager-applet broadcom-wl xfce4-notifyd"
BROWSER="firefox"
XF86="xf86-input-elographics xf86-input-evdev xf86-input-libinput xf86-input-synaptics xf86-input-vmmouse xf86-input-void xf86-input-wacom"
VIRTUAL_AGENTS="hyperv open-vm-tools qemu-guest-agent virtualbox-guest-utils"
FONTS_WIN11="p7zip udisks2 curl expat fuse2 gumbo-parser doxygen help2man"
SYSLINUX="syslinux gptfdisk mtools efibootmgr"
FIRMWARE="ast-firmware upd72020x-fw linux-firmware-qlogic aic94xx-firmware wd719x-firmware"
#CALAMARES="qt5 kpmcore yaml-cpp boost extra-cmake-modules kiconthemes5"
CALAMARES="kconfig kcoreaddons ki18n kiconthemes kio polkit-qt6 qt6-base qt6-svg qt6-tools solid extra-cmake-modules yaml-cpp kpackage kparts kpmcore"

# XF86="xf86-input-elographics xf86-input-evdev xf86-input-libinput xf86-input-synaptics xf86-input-vmmouse xf86-input-void xf86-input-wacom xf86-video-amdgpu xf86-video-ati xf86-video-dummy xf86-video-fbdev xf86-video-intel xf86-video-nouveau xf86-video-openchrome xf86-video-sisusb xf86-video-vesa xf86-video-vmware xf86-video-voodoo xf86-video-qxl"

pacstrap /mnt base base-devel linux linux-headers linux-firmware man-db man-pages texinfo grub efibootmgr $AUR_APPS $EDITOR $XORG $OPENBOX $OPENBOX_MENU $ARCHBANG_APPS $ARCHBANG_ICONS $CODECS $SOUND $NETWORK $BROWSER $XF86 $FONTS_WIN11 $SYSLINUX $FIRMWARE $CALAMARES $VIRTUAL_AGENTS

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# COPYING MAKEPKG.CONF TO ARCHBANGRETRO
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

cp /etc/makepkg.conf /mnt/etc/makepkg.conf

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# COPYING MIRROR LIST TO ARCHBANGRETRO
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/

#
# COPY SCRIPTS FOR CHROOT
#

mkdir -p /mnt${SCRIPTS_DIR} > /dev/null 
cp -R ${CURRENT_DIR}/* /mnt${SCRIPTS_DIR}
printf "${WHITE}\nAll files copied to ${YELLOW}/mnt${SCRIPTS_DIR}${NC}\n\n"

# +-+-+-+-+-+-+-
# CHROOT SCRIPT
# +-+-+-+-+-+-+-

arch-chroot /mnt /bin/bash << EOF

# +-+-+-+-+-+-
# PACMAN.CONF
# +-+-+-+-+-+-

cp /etc/pacman.conf /etc/pacman.conf.chroot
cp /etc/pacman.conf.bck /etc/pacman.conf 

# +-+-+-+-+-+ 
# TIME ZONE
# +-+-+-+-+-+

ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

# +-+-+-+-+-+-+-
# LOCALIZATION
# +-+-+-+-+-+-+-

sed -i "s/#${REGION}/${REGION}/" /etc/locale.gen

locale-gen

printf "LANG=${LANGUAGE}" > /etc/locale.conf 

printf "KEYMAP=${KEYMAP}" > /etc/vconsole.conf


# +-+-+-+-+-+-+-+
# SETUP HOSTNAME
# +-+-+-+-+-+-+-+

printf "${HOSTNAME}" > /etc/hostname

# +-+-+-+-+-+-+-+-+
# SETUP /ETC/HOSTS
# +-+-+-+-+-+-+-+-+

printf "127.0.0.1       localhost\n" > /etc/hosts
printf "::1             localhost\n" >> /etc/hosts
printf "127.0.0.1       ${HOSTNAME}\n" >> /etc/hosts

# +-+-+-+-+-+-+-
# SETUP ROOT PASSWORD
# +-+-+-+-+-+-+-

echo "root:${ROOT_PSW}" | chpasswd

# +-+-+-+-+-+-+-+-+-+
# INSTALL BOOTLOADER
# +-+-+-+-+-+-+-+-+-+

cd ${SCRIPTS_DIR}
source ./bootloader_grub.sh

# +-+-+-+-+-+-+-+-+-+-+-+-+-+
# VI --> VIM symbolink link.
# +-+-+-+-+-+-+-+-+-+-+-+-+-+

ln -s /usr/bin/vim /usr/bin/vi

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# CLS --> CLEAR symbolink link.
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

ln -s /usr/bin/clear /usr/bin/cls

# +-+-+-+-+-
# NETWORKING
# +-+-+-+-+-

# systemctl enable NetworkManager.service

# +-+-+-+-+-+-+-+
# ENABLE OPENSSH
# +-+-+-+-+-+-+-+

systemctl enable sshd

# +-+-+-+-+-+-+-+-+-+-+-+-
# SET DEFAULT ICONS THEME
# +-+-+-+-+-+-+-+-+-+-+-+-

cat > "/usr/share/icons/default/index.theme" << "EOT"
[Icon Theme]
Inherits=gnome-carbonate
EOT

# +-+-+-+-+-
# /ETC/SKEL
# +-+-+-+-+-

mkdir -p /etc/skel/.config
mkdir -p /etc/skel/.icons
mkdir -p /etc/skel/.local/share/file-manager/actions/
mkdir -p /etc/skel/.mozilla
mkdir -p /etc/skel/.screenlayout

cp ${ARCHBANGRETRO_FOLDER}/skel/conkyrc /etc/skel/.conkyrc
cp ${ARCHBANGRETRO_FOLDER}/skel/conkyrc1 /etc/skel/.conkyrc1
cp -R ${ARCHBANGRETRO_FOLDER}/skel/ICONS/* /etc/skel/.icons
cp ${ARCHBANGRETRO_FOLDER}/skel/bashrc /etc/skel/.bashrc
cp -R ${ARCHBANGRETRO_FOLDER}/skel/CONFIG/* /etc/skel/.config/
cp ${ARCHBANGRETRO_FOLDER}/skel/gtkrc-2.0 /etc/skel/.gtkrc-2.0
cp ${ARCHBANGRETRO_FOLDER}/skel/local/terminal.desktop /etc/skel/.local/share/file-manager/actions/
cp -R ${ARCHBANGRETRO_FOLDER}/skel/mozilla/* /etc/skel/.mozilla
# cp -R ${ARCHBANGRETRO_FOLDER}/skel/screenlayout/* /etc/skel/.screenlayout

cat > "/etc/skel/.xinitrc" << "EOT"
exec openbox-session
EOT

# +-+-+-+-+-+-
# CREATE USER
# +-+-+-+-+-+-

useradd -m -G wheel,disk -s /bin/bash $ARCH_USER

echo "${ARCH_USER}:${USER_PSW}" | chpasswd

sed -i 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# DECLARE PYTHONHOME FOR PKGBUILD
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

cd ${SCRIPTS_DIR}
source ./pythonhome.sh

# +-+-+-+-+-+-+-+-
# GNOME-CARBONATE
# +-+-+-+-+-+-+-+-

gtk-update-icon-cache -f -t /usr/share/icons/gnome-carbonate/

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# SLIM THEMES AND CONFIGURATION
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

# cp -R ${ARCHBANGRETRO_FOLDER}/slim/themes /usr/share/slim/

# cp ${ARCHBANGRETRO_FOLDER}/slim/slim.conf /etc/

# +-+-+-+-
# RC.CONF
# +-+-+-+-

cp ${ARCHBANGRETRO_FOLDER}/RC_conf/rc.conf /etc/

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# OPENBOX-MENU WILL BE USING THIS MENU SCHEME
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+- 

cp ${ARCHBANGRETRO_FOLDER}/apps_menu/applications.menu /etc/xdg/menus/ 

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# CONKYWONKY and CONKYSWITCHER
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

cp ${ARCHBANGRETRO_FOLDER}/conky/conkywonky /usr/bin/
chmod +x /usr/bin/conkywonky

cp ${ARCHBANGRETRO_FOLDER}/conky/conkyswitcher /usr/bin/
chmod +x /usr/bin/conkyswitcher

# +-+-+-+-+-+-+-
# AB & DOC.html
# +-+-+-+-+-+-+-

mkdir -p /usr/share/ab
cp ${ARCHBANGRETRO_FOLDER}/ab/DOC.html /usr/share/ab/
cp ${ARCHBANGRETRO_FOLDER}/ab/ab.png /usr/share/ab/
chmod +x /usr/share/ab/DOC.html
chmod +x /usr/share/ab/ab.png

# +-+-+-+-+-+-
# ENABLE SLIM
# +-+-+-+-+-+-

# systemctl enable slim.service

# +-+-+-+-+-+-+-+-+-+
# FIREFOX EXTENSIONS
# +-+-+-+-+-+-+-+-+-+

mkdir -p /usr/lib/firefox/distribution/extensions
cp ${ARCHBANGRETRO_FOLDER}/firefox/* /usr/lib/firefox/distribution/extensions/
chmod +x /usr/lib/firefox/distribution/extensions/* 

#+-+-+-+-+-+-
# NM-APPLET
#+-+-+-+-+-+-

# sed -i 's/Exec=nm-applet/Exec=nm-applet --sm-disable/g' /etc/xdg/autostart/nm-applet.desktop

#+-+-+-+-+-+-+-+
# XFCE4-NOTIFYD
#+-+-+-+-+-+-+-+

# gawk -i inplace '!/OnlyShowIn/' /etc/xdg/autostart/xfce4-notifyd.desktop

# +-+-+-+-+-+-+-+-+-+-+
# MHWD-MANJARO INSTALL
# +-+-+-+-+-+-+-+-+-+-+

if [ ${NVIDIA} = "YES" ]; then
  
  if [ ${NVIDIA_LEGACY} = "YES" ]; then
     
     cd /home/${ARCH_USER}
     sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/nvidia-340xx-utils.git
     cd /home/${ARCH_USER}/nvidia-340xx-utils
     sudo -u ${ARCH_USER} makepkg -s
     pacman -U ./nvidia-340xx-utils*.pkg.tar.zst --noconfirm
     rm -rf /home/${ARCH_USER}/nvidia-340xx-utils
     
     cd /home/${ARCH_USER}
     sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/nvidia-340xx-lts.git
     cd /home/${ARCH_USER}/nvidia-340xx-lts
     sudo -u ${ARCH_USER} makepkg -s
     pacman -U ./nvidia-340xx-lts*.pkg.tar.zst --noconfirm --overwrite=*
     rm -rf /home/${ARCH_USER}/nvidia-340xx-lts

     cp ${ARCHBANGRETRO_FOLDER}/nvidia/30-nvidia-ignoreabi.conf /etc/X11/xorg.conf.d/
  
  else 
     mhwd -a pci nonfree 0300
  fi

else 
  mhwd -a pci free 0300
fi

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# Xorg CONFIG for VmWare 1080p
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+

# This is now done at boot via slim.service

# cd ${SCRIPTS_DIR}
# source ./slim_execstartpre.sh

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# Making sure the graphic virtual drivers 
# are loaded during iniramfs to ensure full screen
# during slim login.
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

cd ${SCRIPTS_DIR}
source ./add_virtualization_graphics_drivers.sh

  
EOF

#
# DONE
#

echo ""
echo "INSTALLATION COMPLETED SUCCESSFULLY !"
echo ""
