#!/bin/bash

set -e  # Script must stop if there is an error.

# +-+-+-+-+
# SETTINGS
# +-+-+-+-+

# Reads the SETTINGS file to define global variables.
source ./SETTINGS

#
# FUNCTIONS
# ========
# 

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# AVAILABLE_MEMORY
# ================
#
# Will determine what is the current memory,
# add 1GB to it and make it the swap size when
# formatting the HD.
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

function make_swap_size () {

  # Use dmidecode to get information about the installed memory on the system.
  # Use awk to extract the sizes of the memory modules.
  # Use numfmt to convert these sizes to bytes.
  # Use awk to calculate the total memory size.
  # Use numfmt again to convert the total size back to a human-readable format with a whole number.

  physical_memory=$(
	dmidecode -t memory |
	awk '$1 == "Size:" && $2 ~ /^[0-9]+$/ {print $2$3}' |
	numfmt --from=iec --suffix=B |
	awk '{total += $1}; END {print total}' |
	numfmt --to=iec --suffix=B --format=%0f
  )

  # Extract the integer portion of the physical_memory variable and increment it by one.
  # This is often recommended to set the swap size to be equal to or slightly larger than the amount of physical memory in the system.

  SWAP_SIZE=${physical_memory%.*}
  SWAP_SIZE=$((SWAP_SIZE+1))

  # Multiply the integer value of physical_memory by 1024, which converts the value from megabytes to kilobytes.
  # Swap sizes are often specified in kilobytes.

  SWAP_SIZE=$((SWAP_SIZE * 1024))
}

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
    printf "\n${CYAN}This script needs to be ran with admin privileges to execute properly.\n"

  yes_or_no "${YELLOW}Would you like to run it again with the SUDO command?${NC}" "y"

  case $Y_N_ANSWER in
    [Yy]* ) printf "${NC}"; sudo ./archbangretroinstall.sh; exit;;
    [Nn]* ) printf "\n${CYAN}Bye bye...\n\n${NC}"; exit;;
  esac

fi

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# ENABLE ALL OUTPUTS TO BE SENT
# TO LOG.OUT DURING THE SCRIPT
# FOR DEBUGGING USAGE.
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

echo ""
yes_or_no "Would you like to have the outputs into log.out?" "n"

if [ "$Y_N_ANSWER" == Y ]; then
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3
  exec 1>log.out 2>&1
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
printf "${GREEN}MIRRORS COUNTRY = ${CYAN}${REFLECTOR_COUNTRY}\n\n"
printf "${GREEN}NVIDIA        = ${CYAN}${NVIDIA}\n"
printf "${GREEN}NVIDIA_LEGACY = ${CYAN}${NVIDIA_LEGACY}\n\n"

printf "${GREEN}ARCHBANGRETRO_FILE_URL = ${CYAN}${ARCHBANGRETRO_FILE_URL}\n"
printf "${GREEN}MANJARO_FILE_URL       = ${CYAN}${MANJARO_FILE_URL}\n\n"

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

countsleep "Automatic install will start in... " 30 

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# INSTALL THE NEEDED DEPENDENCIES 
# TO RUN THIS SCRIPT FROM ARCH LIVE CD
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

printf "${CYAN}Updating archlinux's repos.\n${NC}"
pacman -Sy > /dev/null

if ! pacman -Qs dmidecode > /dev/null ; then
	printf "Installing dmidecode...\n"
	pacman -S dmidecode --noconfirm > /dev/null
fi

if ! pacman -Qs reflector > /dev/null ; then
	printf "Installing reflector...\n"
	pacman -S reflector --noconfirm > /dev/null
fi

printf "\n${NC}"

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# ENABLE MIRRORS FROM $MIRROR_LINK
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

printf "${YELLOW}Setting up best mirrors from ${REFLECTOR_COUNTRY} for this live session.\n\n${NC}" 

reflector --country "${REFLECTOR_COUNTRY}" --sort score --score 5 --protocol https --save /etc/pacman.d/mirrorlist

countsleep "Partitioning the disk will start in... " 5

# +-+-+-+-+-+-+-+-+-+-+-+-
# UPDATE THE SYSTEM CLOCK 
# +-+-+-+-+-+-+-+-+-+-+-+-

timedatectl set-ntp true

# +-+-+-+-+-+-+-+-+-+-
# PARTITION THE DISKS
# +-+-+-+-+-+-+-+-+-+-

make_swap_size

if mount | grep /mnt > /dev/null; then
  umount -R /mnt
fi 

wipefs -a $DRIVE --force 

if [ ${FIRMWARE} = "BIOS" ]; then
  parted -a optimal $DRIVE --script mklabel msdos
  parted -a optimal $DRIVE --script unit mib

  parted -a optimal $DRIVE --script mkpart primary 2048 3072
  parted -a optimal $DRIVE --script set 1 boot on

  parted -a optimal $DRIVE --script mkpart primary 3072 $SWAP_SIZE

  parted -a optimal $DRIVE --script mkpart primary $SWAP_SIZE -- -1

else
  parted -a optimal $DRIVE --script mklabel gpt
  parted -a optimal $DRIVE --script unit mib

  parted -a optimal $DRIVE --script mkpart primary 1 1025
  parted -a optimal $DRIVE --script name 1 boot
  parted -a optimal $DRIVE --script set 1 boot on

  parted -a optimal $DRIVE --script mkpart primary 1025 $SWAP_SIZE
  parted -a optimal $DRIVE --script name 2 swap

  parted -a optimal $DRIVE --script mkpart primary $SWAP_SIZE -- -1
  parted -a optimal $DRIVE --script name 3 rootfs

fi


# +-+-+-+-+-+-+-+-+-+-+-
# FORMAT THE PARTITIONS
# +-+-+-+-+-+-+-+-+-+-+-

if [ ${FIRMWARE} = "BIOS" ]; then
  yes | mkfs.ext2 ${DRIVE_PART1}
else
  yes | mkfs.fat -F32 ${DRIVE_PART1}
fi

yes | mkswap ${DRIVE_PART2}
yes | swapon ${DRIVE_PART2}
yes | mkfs.ext4 ${DRIVE_PART3}

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# MOUNT THE NEWLY CREATED PARTITIONS
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

mount /${DRIVE_PART3} /mnt
mkdir /mnt/boot
mount ${DRIVE_PART1} /mnt/boot

# +-+-+-+-+-+-+-+-+-+-+-
# MHWD-MANJARO DOWNLOAD
# +-+-+-+-+-+-+-+-+-+-+-

# Specify the directory where the files will be downloaded and extracted
TARGET_DIRECTORY="/mnt/"

# Initialize FILE_LIST and V86D_FILE_LIST as empty variables
FILE_LIST=""
V86D_FILE_LIST=""

# Change to the target directory
cd ${TARGET_DIRECTORY}

# Print a blank line
echo

# Print the title
echo -e "${WHITE}MHWD MANJARO INSTALLATION${NC}"

# Print a line of asterisks
echo -e "${WHITE}*************************${NC}"

# Print a blank line
echo

# Import manjaro.gpg if not already installed
if ! gpg --list-keys manjaro >/dev/null 2>&1; then
    echo -e "${CYAN}Importing manjaro.gpg...${NC}"
    echo
    curl -s "$MANJARO_GPG_URL" | gpg --import
    echo
    echo -e "${GREEN}manjaro.gpg imported successfully!${NC}"
else
    echo -e "${GREEN}manjaro.gpg is already installed.${NC}"
fi

echo

printf "${YELLOW}Retrieve list of mhwd-manjaro files...${NC}\n\n"

# Fetch the HTML content of the URL and extract the file names

printf "${CYAN}1) mhwd\n"
FILE_LIST=$(curl -s "$MHWD_URL" | grep -oP 'mhwd[^"]*\.tar\.zst')

printf "${CYAN}2) v86d\n\n${NC}"
V86D_FILE_LIST=$(curl -s "$MHWD_URL" | grep -oP 'v86d[^"]*\.tar\.zst')

# Function to download and extract files
download_and_extract() {
    local FILE_NAME="$1"
    local PGP_FILE_NAME="$FILE_NAME.sig"

    if [[ ! -e "$FILE_NAME" ]]; then
        echo -e "${YELLOW}Downloading $FILE_NAME...${NC}"
        curl -s -O "$MHWD_URL$FILE_NAME" > /dev/null

        echo -e "${YELLOW}Downloading $PGP_FILE_NAME...${NC}"
        curl -s -O "$MHWD_URL$PGP_FILE_NAME" > /dev/null

        echo -e "${GREEN}Verifying $FILE_NAME...${NC}"
        GPG_OUTPUT=$(gpg --verify "$PGP_FILE_NAME" "$FILE_NAME" 2>&1)
        if [[ $GPG_OUTPUT =~ "Good signature" ]]; then
            echo -e "${GREEN}Verification successful!${NC}"
        else
            echo -e "${RED}Verification failed:${NC}"
            echo "$GPG_OUTPUT"
        fi

        echo -e "${GREEN}Extracting $FILE_NAME...${NC}"
        tar -xf "$FILE_NAME" -C "$TARGET_DIRECTORY"
        echo -e "${WHITE}Extraction completed!${NC}"
        echo

        local SIG_FILE="${FILE_NAME}.sig"
        if [[ -e "$SIG_FILE" ]]; then
            rm "$SIG_FILE"
        fi
    fi
}

# Download and extract mhwd*.tar.zst files
for FILE in $FILE_LIST; do
    download_and_extract "$FILE"
done

# Download and extract v86d*.tar.zst files
for FILE in $V86D_FILE_LIST; do
    download_and_extract "$FILE"
done

echo -e "${YELLOW}All files downloaded and extracted.${NC}"

# Clean up downloaded packages
printf "${CYAN}Cleaning up downloaded packages...${NC}"
for FILE in $FILE_LIST $V86D_FILE_LIST; do
    if [[ -e "$FILE" ]]; then
        rm "$FILE"
        printf "."
    fi
done

echo
echo -e "${GREEN}Cleanup completed${NC}"


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

curl -fLO "${ARCHBANGRETRO_FILE_URL}"
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


# +-+-+-+-+-+-+-+-+
# INSTALL PACKAGES
# +-+-+-+-+-+-+-+-+

EDITOR="vim nano"
CATFISH_DEPENDENCIES="dbus-python python-pyxdg"
DEPENDENCIES="hwinfo go gnome-themes-standard git intltool python-cairo python-gobject python-pillow libxft libxinerama gdk-pixbuf-xlib python-distutils-extra cmake cblas lapack gcc-fortran"
XORG="xorg-server xorg-xinit xorg-xkill"
OPENBOX="openbox ttf-dejavu ttf-liberation"
OPENBOX_MENU="glib2 gtk2 menu-cache gnome-menus lxmenu-data"
ARCHBANG_APPS="catfish reflector lxterminal lxappearance lxappearance-obconf lxinput leafpad gucharmap pcmanfm galculator parcellite xarchiver shotwell htop arandr obconf tint2 conky xcompmgr nitrogen scrot exo gnome-mplayer xfburn libfm-gtk2 gmrun slim packer arj cronie dialog dnsutils gnome-keyring gsimplecal gtk-engine-murrine gtk-engines inetutils jfsutils logrotate lzop memtest86+ modemmanager ntfs-3g p7zip reiserfsprogs rsync squashfs-tools syslinux tcl unrar unzip usb_modeswitch zip gvfs cbatticon xdg-utils"
ARCHBANG_ICONS="gtk-update-icon-cache hicolor-icon-theme librsvg icon-naming-utils intltool" 
CODECS="a52dec faac faad2 jasper lame libdca libdv libmad libmpeg2 libtheora libvorbis libxv wavpack x264 xvidcore gstreamer"
SOUND="volumeicon alsa-utils pulseaudio alsa-firmware alsa-oss"
NETWORK="network-manager-applet broadcom-wl xfce4-notifyd"
BROWSER="firefox"
XF86="xf86-input-elographics xf86-input-evdev xf86-input-libinput xf86-input-synaptics xf86-input-vmmouse xf86-input-void xf86-input-wacom"
CALAMARES="qt5 kpmcore yaml-cpp boost extra-cmake-modules kiconthemes"


# XF86="xf86-input-elographics xf86-input-evdev xf86-input-libinput xf86-input-synaptics xf86-input-vmmouse xf86-input-void xf86-input-wacom xf86-video-amdgpu xf86-video-ati xf86-video-dummy xf86-video-fbdev xf86-video-intel xf86-video-nouveau xf86-video-openchrome xf86-video-sisusb xf86-video-vesa xf86-video-vmware xf86-video-voodoo xf86-video-qxl"

pacstrap /mnt base base-devel linux-lts linux-lts-headers linux-firmware man-db man-pages texinfo grub efibootmgr $EDITOR $DEPENDENCIES $CATFISH_DEPENDENCIES $XORG $OPENBOX $OPENBOX_MENU $ARCHBANG_APPS $ARCHBANG_ICONS $CODECS $SOUND $NETWORK $BROWSER $XF86 $CALAMARES

# +-+-+-+-+-+-+-+-+
# SETUP /ETC/FSTAB
# +-+-+-+-+-+-+-+-+

genfstab -U /mnt >> /mnt/etc/fstab

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# COPYING MIRROR LIST TO ARCHBANGRETRO
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/

# +-+-+-+-+-+-+-
# CHROOT SCRIPT
# +-+-+-+-+-+-+-

arch-chroot /mnt /bin/bash << EOF

# +-+-+-+-+-+-+-+-
# ENABLE MULTILIB
# +-+-+-+-+-+-+-+-

sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy > /dev/null

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

if [ ${FIRMWARE} = "BIOS" ]; then
  grub-install --target=i386-pc ${DRIVE}
else
  grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
fi

grub-mkconfig -o /boot/grub/grub.cfg

# +-+-+-+-+-+-+-+-+-+-+-+-+-+
# VI --> VIM symbolink link.
# +-+-+-+-+-+-+-+-+-+-+-+-+-+

ln -s /usr/bin/vim /usr/bin/vi

# +-+-+-+-+-
# NETWORKING
# +-+-+-+-+-

systemctl enable NetworkManager.service

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

cp ${ARCHBANGRETRO_FOLDER}/skel/conkyrc /etc/skel/.conkyrc
cp ${ARCHBANGRETRO_FOLDER}/skel/conkyrc1 /etc/skel/.conkyrc1
cp -R ${ARCHBANGRETRO_FOLDER}/skel/ICONS/* /etc/skel/.icons
cp ${ARCHBANGRETRO_FOLDER}/skel/bashrc /etc/skel/.bashrc
cp -R ${ARCHBANGRETRO_FOLDER}/skel/CONFIG/* /etc/skel/.config/
cp ${ARCHBANGRETRO_FOLDER}/skel/gtkrc-2.0 /etc/skel/.gtkrc-2.0
cp ${ARCHBANGRETRO_FOLDER}/skel/local/terminal.desktop /etc/skel/.local/share/file-manager/actions/
cp -R ${ARCHBANGRETRO_FOLDER}/skel/mozilla/* /etc/skel/.mozilla

cat > "/etc/skel/.xinitrc" << "EOT"
exec openbox-session
EOT

# +-+-+-+-+-+-
# CREATE USER
# +-+-+-+-+-+-

useradd -m -G wheel -s /bin/bash $ARCH_USER

echo "${ARCH_USER}:${USER_PSW}" | chpasswd

sed -i 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# +-+-+-+-+-+
# ALPM-HOOKS
# +-+-+-+-+-+

mkdir -p /etc/pacman.d/hooks

   # +-+-+-+-
   # PCMANFM
   # +-+-+-+-

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/pcmanfm_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/pcmanfm_install.hook
   printf "rm /usr/share/applications/pcmanfm-desktop-pref.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/pcmanfm_install.sh
   printf "cp ${ARCHBANGRETRO_FOLDER}/applications/pcmanfm.desktop /usr/share/applications/" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/pcmanfm_install.sh

   # +-+-+-+-+-
   # CBATTICON
   # +-+-+-+-+-

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/cbatticon_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/cbatticon_install.hook
   printf "cp ${ARCHBANGRETRO_FOLDER}/applications/batti.desktop /usr/share/applications/" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/cbatticon_install.sh

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/cbatticon_uninstall.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/cbatticon_uninstall.hook
   printf "rm /usr/share/applications/batti.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/cbatticon_uninstall.sh

   # +-+-+-+-+
   # SHOTWELL
   # +-+-+-+-+

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/shotwell_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/shotwell_install.hook
   printf "cp ${ARCHBANGRETRO_FOLDER}/applications/org.gnome.Shotwell.desktop /usr/share/applications/" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/shotwell_install.sh
   printf "rm /usr/share/applications/org.gnome.Shotwell-Profile-Browser.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/shotwell_install.sh
   printf "rm /usr/share/applications/org.gnome.Shotwell-Viewer.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/shotwell_install.sh

   # +-+-+-+-+
   # CATFISH
   # +-+-+-+-+

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/catfish_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/catfish_install.hook
   printf "cp ${ARCHBANGRETRO_FOLDER}/applications/org.xfce.Catfish.desktop /usr/share/applications/" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/catfish_install.sh
  
   # +-+-+-+-
   # XFBURN
   # +-+-+-+-

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/xfburn_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/xfburn_install.hook
   printf "cp ${ARCHBANGRETRO_FOLDER}/applications/xfburn.desktop /usr/share/applications/" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/xfburn_install.sh

   # +-+-
   # EXO
   # +-+-

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/exo_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/exo_install.hook
   printf "cp ${ARCHBANGRETRO_FOLDER}/applications/exo-preferred-applications.desktop /usr/share/applications/" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/exo_install.sh

   # +-+-+-+-+-+
   # LIBFM-GTK2
   # +-+-+-+-+-+

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/libfm-gtk2_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/libfm-gtk2_install.hook
   printf "cp ${ARCHBANGRETRO_FOLDER}/applications/exo-preferred-applications.desktop /usr/share/applications/" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/libfm-gtk2_install.sh

   # +-+-+-+-+-+
   # LXTERMINAL
   # +-+-+-+-+-+

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/lxterminal_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/lxterminal_install.hook
   printf "cp ${ARCHBANGRETRO_FOLDER}/applications/lxterminal.desktop /usr/share/applications/" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/lxterminal_install.sh

   # +-+-+-+-+-+-+-+-+-+-+-+
   # NETWORK-MANAGER-APPLET
   # +-+-+-+-+-+-+-+-+-+-+-+

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/network-manager-applet_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/network-manager-applet_install.hook
   printf "cp ${ARCHBANGRETRO_FOLDER}/applications/nm-connection-editor.desktop /usr/share/applications/\n" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/network-manager-applet_install.sh
   printf "sed -i 's/Exec=nm-applet/Exec=nm-applet --sm-disable/g' /etc/xdg/autostart/nm-applet.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/network-manager-applet_install.sh

   # +-+-+-+-+-+-+-+-+-+
   # GNOME-DISK-UTILITY
   # +-+-+-+-+-+-+-+-+-+

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/gnome-disk-utility_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/gnome-disk-utility_install.hook
   printf "cp ${ARCHBANGRETRO_FOLDER}/applications/org.gnome.DiskUtility.desktop /usr/share/applications/" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/gnome-disk-utility_install.sh

   # +-+-+-
   # TINT2
   # +-+-+-

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/tint2_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/tint2_install.hook
   printf "cp ${ARCHBANGRETRO_FOLDER}/applications/tint2conf.desktop /usr/share/applications/" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/tint2conf_install.sh

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/tint2_uninstall.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/tint2_uninstall.hook
   printf "rm /usr/share/applications/tint2conf.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/tint2_uninstall.sh

   # +-+-+-+-+-+-+-
   # HARDINFO-GIT
   # +-+-+-+-+-+-+-

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/hardinfo-git_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/hardinfo-git_install.hook
   printf "cp ${ARCHBANGRETRO_FOLDER}/applications/hardinfo.desktop /usr/share/applications/" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/hardinfo-git_install.sh

   # +-+-+-
   # GMRUN
   # +-+-+-

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/gmrun_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/gmrun_install.hook
   printf "rm /usr/share/applications/gmrun.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/gmrun_install.sh

   # +-+-+-+-+
   # NITROGEN
   # +-+-+-+-+

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/nitrogen_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/nitrogen_install.hook
   printf "rm /usr/share/applications/nitrogen.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/nitrogen_install.sh

   # +-+-
   # VIM
   # +-+-

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/vim_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/vim_install.hook
   printf "rm /usr/share/applications/vim.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/vim_install.sh

   # +-+-+-
   # AVAHI
   # +-+-+-

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/avahi_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/avahi_install.hook
   printf "rm /usr/share/applications/avahi-discover.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/avahi_install.sh
   printf "rm /usr/share/applications/bssh.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/avahi_install.sh
   printf "rm /usr/share/applications/bvnc.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/avahi_install.sh

   # +-+-+-+-+-
   # V4L-UTILS
   # +-+-+-+-+-

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/v4l-utils_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/v4l-utils_install.hook
   printf "rm /usr/share/applications/qv4l2.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/v4l-utils_install.sh
   printf "rm /usr/share/applications/qvidcap.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/v4l-utils_install.sh

   # +-+-+-
   # CMAKE
   # +-+-+-

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/cmake_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/cmake_install.hook
   printf "rm /usr/share/applications/cmake-gui.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/cmake_install.sh

   # +-+-+-
   # CONKY
   # +-+-+-

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/conky_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/conky_install.hook
   printf "rm /usr/share/applications/conky.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/conky_install.sh

   # +-+-+-+-
   # LXINPUT
   # +-+-+-+-

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/lxinput_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/lxinput_install.hook
   printf "rm /usr/share/applications/lxinput.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/lxinput_install.sh

   # +-+-+-+-+-+
   # VOLUMEICON
   # +-+-+-+-+-+

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/volumeicon_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/volumeicon_install.hook
   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/volumeicon_uninstall.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/volumeicon_uninstall.hook

   printf "cp ${ARCHBANGRETRO_FOLDER}/applications/volumeicon.desktop /etc/xdg/autostart/\n" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/volumeicon_install.sh
   printf "rm /usr/share/applications/volumeicon.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/volumeicon_install.sh

   printf "rm /etc/xdg/autostart/volumeicon.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/volumeicon_uninstall.sh


   # +-+-+-+
   # LIBGDA
   # +-+-+-+

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/libgda_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/libgda_install.hook
   printf "rm /usr/share/applications/gda-browser-5.0.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/libgda_install.sh
   printf "rm /usr/share/applications/gda-control-center-5.0.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/libgda_install.sh

   # +-+-+-
   # GMRUN
   # +-+-+-

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/gmrun_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/gmrun_install.hook
   printf "rm /usr/share/applications/gmrun.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/gmrun_install.sh

   # +-+-+-+-+-+-+-+-+-+
   # XFCE4-NOTIFYD
   # +-+-+-+-+-+-+-+-+-+

   printf "Exec = ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/xfce4-notifyd_install.sh" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/xfce4-notifyd_install.hook
   printf "gawk -i inplace '!" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/xfce4-notifyd_install.sh
   printf "/OnlyShowIn/' /etc/xdg/autostart/xfce4-notifyd.desktop" >> ${ARCHBANGRETRO_FOLDER}/HOOKS/scripts/xfce4-notifyd_install.sh


cp -R ${ARCHBANGRETRO_FOLDER}/HOOKS/* /etc/pacman.d/hooks/ 


# +-+-+-+-
# PYTHON2
# +-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/python2-bin.git
cd /home/${ARCH_USER}/python2-bin
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./python2-bin*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/python2-bin

# cd /home/${ARCH_USER}
# sudo -u ${ARCH_USER} curl -fLO https://archive.archlinux.org/packages/p/python2/python2-2.7.18-5-x86_64.pkg.tar.zst
# pacman -U ./python2*.pkg.tar.zst --noconfirm
# rm -f python2*.pkg.tar.zst

# +-+-+-+-+-+-+-+-+-+
# PYTHON2-SETUPTOOLS
# +-+-+-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} curl -fLO https://archive.archlinux.org/packages/p/python2-setuptools/python2-setuptools-2:44.1.1-2-any.pkg.tar.zst
pacman -U ./python2-setuptools*.pkg.tar.zst --noconfirm
rm -f python2-setuptools*.pkg.tar.zst

# +-+-+-+-+
# CYTHON2
# +-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/cython2.git
cd /home/${ARCH_USER}/cython2
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./cython2*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/cython2


# +-+-+-+-+-+-+-+-+-+-+-+-+-
# GNOME-ICON-THEME-SYMBOLIC (dependency for gnome-icon-theme)
# +-+-+-+-+-+-+-+-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/gnome-icon-theme-symbolic.git
cd /home/${ARCH_USER}/gnome-icon-theme-symbolic
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./gnome-icon-theme-symbolic*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/gnome-icon-theme-symbolic


# +-+-+-+-+-+-+-+-+
# GNOME-ICON-THEME
# +-+-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/gnome-icon-theme.git
cd /home/${ARCH_USER}/gnome-icon-theme
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./gnome-icon-theme*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/gnome-icon-theme


# +-+-
# YAY
# +-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/yay.git
cd /home/${ARCH_USER}/yay
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./yay*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/yay

# +-+-+-+-+-+-
# OBMENU2-GIT
# +-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/obmenu2-git.git
cd /home/${ARCH_USER}/obmenu2-git
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./obmenu2*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/obmenu2-git

# +-+-+-+-+-+-
# BATTI-ICONS
# +-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/batti-icons.git
cd /home/${ARCH_USER}/batti-icons
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./batti-icons*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/batti-icons

# +-+-+-+-+-+-+-+-+
# OBLOGOUT-PY3-GIT
# +-+-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/oblogout-py3-git.git
cd /home/${ARCH_USER}/oblogout-py3-git
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./oblogout-py3-git*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/oblogout-py3-git

# +-+-+-+-+-+-+-+-+
# PYTHON2-GOBJECT2 (dependency for pygtk)
# +-+-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/python2-gobject2.git
cd /home/${ARCH_USER}/python2-gobject2
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./python2-gobject2*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/python2-gobject2

# +-+-+-+-+
# DEADBEEF
# +-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} curl -fLO https://archive.archlinux.org/packages/d/deadbeef/deadbeef-1.8.4-1-x86_64.pkg.tar.zst
pacman -U ./deadbeef*.pkg.tar.zst --noconfirm
rm -f deadbeef*.pkg.tar.zst

# +-+-+-+-+
# LIBGLADE
# +-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} curl -fLO https://archive.archlinux.org/packages/l/libglade/libglade-2.6.4-7-x86_64.pkg.tar.zst
pacman -U ./libglade*.pkg.tar.zst --noconfirm
rm -f libglade*.pkg.tar.zst

# +-+-+-+-+-+-+-
# PYTHON2-CAIRO (dependency for PYGTK)
# +-+-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/python2-cairo.git
cd /home/${ARCH_USER}/python2-cairo
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./python2-cairo*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/python2-cairo

# +-+-+-+-+-+-+-
# PYTHON2-NUMPY (dependency for PYGTK)
# +-+-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/python2-numpy.git
cd /home/${ARCH_USER}/python2-numpy
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./python2-numpy*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/python2-numpy

# +-+-+-
# PYGTK (dependency for catfish-python2 and obkey)
# +-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/pygtk.git
cd /home/${ARCH_USER}/pygtk
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./pygtk*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/pygtk

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# PYTHON2-DBUS (dependency for catfish-python2)
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

mkdir /home/${ARCH_USER}/python2-dbus
cd /home/${ARCH_USER}/python2-dbus
curl -fLO https://archive.archlinux.org/repos/2021/02/28/extra/os_x86_64/python2-dbus-1.2.16-3-x86_64.pkg.tar.zst
pacman -U ./python2-dbus*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/python2-dbus

# +-+-+-
# OBKEY 
# +-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/obkey.git
cd /home/${ARCH_USER}/obkey
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./obkey*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/obkey

# +-+-+-+
# DMENU2 
# +-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/dmenu2.git
cd /home/${ARCH_USER}/dmenu2
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./dmenu2*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/dmenu2

# +-+-+-+-+-+-+-+-
# GNOME-CARBONATE
# +-+-+-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/gnome-carbonate.git
cd /home/${ARCH_USER}/gnome-carbonate
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./gnome-carbonate*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/gnome-carbonate

gtk-update-icon-cache -f -t /usr/share/icons/gnome-carbonate/

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-
# GNOME-COLORS-ICON-THEME-BIN
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/gnome-colors-icon-theme-bin.git
cd /home/${ARCH_USER}/gnome-colors-icon-theme-bin
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./gnome-colors-icon-theme-bin*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/gnome-colors-icon-theme-bin

gtk-update-icon-cache -f -t /usr/share/icons/gnome-colors-icon-theme/

rm -rf /usr/share/icons/gnome-brave
rm -rf /usr/share/icons/gnome-dust
rm -rf /usr/share/icons/gnome-human
rm -rf /usr/share/icons/gnome-illustrious
rm -rf /usr/share/icons/gnome-noble
rm -rf /usr/share/icons/gnome-tribute
rm -rf /usr/share/icons/gnome-wine
rm -rf /usr/share/icons/gnome-wise

# +-+-+-+-+- 
# WALLPAPER
# +-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/archbangretro-wallpaper.git
cd /home/${ARCH_USER}/archbangretro-wallpaper
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./archbangretro-wallpaper*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/archbangretro-wallpaper

# +-+-+-+-+-+-+-
# OPENBOX-MENU
# +-+-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/openbox-menu.git
cd /home/${ARCH_USER}/openbox-menu
# sed -i '/patch -i ../d' ./PKGBUILD
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./openbox-menu*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/openbox-menu

# +-+-+-+
# FBXKB 
# +-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/fbxkb.git
cd /home/${ARCH_USER}/fbxkb
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./fbxkb*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/fbxkb

# +-+-+-+-+-+-+-+
# OPENBOX-THEMES 
# +-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/openbox-themes.git
cd /home/${ARCH_USER}/openbox-themes
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./openbox-themes*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/openbox-themes

# +-+-+-+-
# ARCHBEY
# +-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/archbey.git
cd /home/${ARCH_USER}/archbey
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./archbey*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/archbey

# +-+-+-+-+
# EPDFVIEW
# +-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} curl -fLO https://archive.archlinux.org/packages/e/epdfview/epdfview-0.1.8-11-x86_64.pkg.tar.zst 
pacman -U ./epdfview*.pkg.tar.zst --noconfirm
rm -f epdfview*.pkg.tar.zst

# +-+-+-+-+-+-+-+
# MADPABLO-THEME
# +-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/madpablo-theme.git
cd /home/${ARCH_USER}/madpablo-theme
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./madpablo-theme*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/madpablo-theme

# +-+-+-+-+-+-+-+
# FLAT-REMIX-GTK
# +-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/flat-remix-gtk.git
cd /home/${ARCH_USER}/flat-remix-gtk
sudo -u ${ARCH_USER} makepkg -s
pacman -U ./flat-remix-gtk*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/flat-remix-gtk

rm -rf /usr/share/themes/Flat-Remix-GTK-Black-*

rm -rf /usr/share/themes/Flat-Remix-GTK-Blue-Dark-*
rm -rf /usr/share/themes/Flat-Remix-GTK-Blue-Darke*
rm -rf /usr/share/themes/Flat-Remix-GTK-Blue-Solid
rm -rf /usr/share/themes/Flat-Remix-GTK-Blue-Light*

rm -rf /usr/share/themes/Flat-Remix-GTK-Green-Dark-*
rm -rf /usr/share/themes/Flat-Remix-GTK-Green-Darke*
rm -rf /usr/share/themes/Flat-Remix-GTK-Green-Solid
rm -rf /usr/share/themes/Flat-Remix-GTK-Green-Light*

rm -rf /usr/share/themes/Flat-Remix-GTK-Red-Dark-*
rm -rf /usr/share/themes/Flat-Remix-GTK-Red-Darke*
rm -rf /usr/share/themes/Flat-Remix-GTK-Red-Solid
rm -rf /usr/share/themes/Flat-Remix-GTK-Red-Light*

rm -rf /usr/share/themes/Flat-Remix-GTK-Yellow-Dark-*
rm -rf /usr/share/themes/Flat-Remix-GTK-Yellow-Darke*
rm -rf /usr/share/themes/Flat-Remix-GTK-Yellow-Solid
rm -rf /usr/share/themes/Flat-Remix-GTK-Yellow-Light*

rm -rf /usr/share/themes/Flat-Remix-GTK-Brown-Dark-*
rm -rf /usr/share/themes/Flat-Remix-GTK-Brown-Darke*
rm -rf /usr/share/themes/Flat-Remix-GTK-Brown-Solid
rm -rf /usr/share/themes/Flat-Remix-GTK-Brown-Light*

rm -rf /usr/share/themes/Flat-Remix-GTK-Cyan-Dark-*
rm -rf /usr/share/themes/Flat-Remix-GTK-Cyan-Darke*
rm -rf /usr/share/themes/Flat-Remix-GTK-Cyan-Solid
rm -rf /usr/share/themes/Flat-Remix-GTK-Cyan-Light*

rm -rf /usr/share/themes/Flat-Remix-GTK-Grey-Dark-*
rm -rf /usr/share/themes/Flat-Remix-GTK-Grey-Darke*
rm -rf /usr/share/themes/Flat-Remix-GTK-Grey-Solid
rm -rf /usr/share/themes/Flat-Remix-GTK-Grey-Light*

rm -rf /usr/share/themes/Flat-Remix-GTK-Magenta-Dark-*
rm -rf /usr/share/themes/Flat-Remix-GTK-Magenta-Darke*
rm -rf /usr/share/themes/Flat-Remix-GTK-Magenta-Solid
rm -rf /usr/share/themes/Flat-Remix-GTK-Magenta-Light*

rm -rf /usr/share/themes/Flat-Remix-GTK-Orange-Dark-*
rm -rf /usr/share/themes/Flat-Remix-GTK-Orange-Darke*
rm -rf /usr/share/themes/Flat-Remix-GTK-Orange-Solid
rm -rf /usr/share/themes/Flat-Remix-GTK-Orange-Light*

rm -rf /usr/share/themes/Flat-Remix-GTK-Brown-Dark-*
rm -rf /usr/share/themes/Flat-Remix-GTK-Brown-Darke*
rm -rf /usr/share/themes/Flat-Remix-GTK-Brown-Solid
rm -rf /usr/share/themes/Flat-Remix-GTK-Brown-Light*

rm -rf /usr/share/themes/Flat-Remix-GTK-Teal-Dark-*
rm -rf /usr/share/themes/Flat-Remix-GTK-Teal-Darke*
rm -rf /usr/share/themes/Flat-Remix-GTK-Teal-Solid
rm -rf /usr/share/themes/Flat-Remix-GTK-Teal-Light*

rm -rf /usr/share/themes/Flat-Remix-GTK-Violet-Dark-*
rm -rf /usr/share/themes/Flat-Remix-GTK-Violet-Darke*
rm -rf /usr/share/themes/Flat-Remix-GTK-Violet-Solid
rm -rf /usr/share/themes/Flat-Remix-GTK-Violet-Light*

rm -rf /usr/share/themes/Flat-Remix-GTK-White-Dark-*
rm -rf /usr/share/themes/Flat-Remix-GTK-White-Darke*
rm -rf /usr/share/themes/Flat-Remix-GTK-White-Solid
rm -rf /usr/share/themes/Flat-Remix-GTK-White-Light*

# +-+-+-+-+-+-+-+-+-+
# HARDINFO-GIT
# +-+-+-+-+-+-+-+-+-+

cd ${ARCHBANGRETRO_FOLDER}
git clone https://github.com/Mordillo98/hardinfo-0.6-alpha
cd hardinfo-0.6-alpha
cmake -B build -S . \
		-DCMAKE_BUILD_TYPE='Debug' \
		-DCMAKE_INSTALL_PREFIX='/usr' \
		-DCMAKE_INSTALL_LIBDIR='lib' \
		-DHARDINFO_GTK3='ON' \
		-DHARDINFO_DEBUG='$(usex debug 1 0)' \
		-Wno-dev

make -C build

make -C build DESTDIR="$pkgdir" install

# cd /home/${ARCH_USER}
# sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/hardinfo-git.git
# cd /home/${ARCH_USER}/hardinfo-git
# sudo -u ${ARCH_USER} makepkg -s
# pacman -U ./hardinfo-git*.pkg.tar.zst --noconfirm
# rm -rf /home/${ARCH_USER}/hardinfo-git

# +-+-+-+-+-+-+-+-+-+-+-+-+
# GNOME-DISK-UTILITY-3.4.1
# +-+-+-+-+-+-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
mkdir gnome-disk-utility-3.4.1
cd /home/${ARCH_USER}/gnome-disk-utility-3.4.1
curl -fLO https://sourceforge.net/projects/archbangretro/files/gnome-disk-utility-3.4.1-3.4.1-1-x86_64.pkg.tar.zst
pacman -U ./gnome-disk-utility-3.4.1*.pkg.tar.zst --noconfirm
rm -rf /home/${ARCH_USER}/gnome-disk-utility-3.4.1

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# SLIM THEMES AND CONFIGURATION
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

cp -R ${ARCHBANGRETRO_FOLDER}/slim/themes /usr/share/slim/

cp ${ARCHBANGRETRO_FOLDER}/slim/slim.conf /etc/

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

systemctl enable slim.service

# +-+-+-+-+-+-+-+-+-+
# FIREFOX EXTENSIONS
# +-+-+-+-+-+-+-+-+-+

mkdir -p /usr/lib/firefox/distribution/extensions
cp ${ARCHBANGRETRO_FOLDER}/firefox/* /usr/lib/firefox/distribution/extensions/
chmod +x /usr/lib/firefox/distribution/extensions/* 

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# /ETC/PROFILE 
#
# Make HD resolution available 
# under VMware video.
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

cat ${ARCHBANGRETRO_FOLDER}/profile/profile >> /etc/profile

#+-+-+-+-+-+-
# NM-APPLET
#+-+-+-+-+-+-

sed -i 's/Exec=nm-applet/Exec=nm-applet --sm-disable/g' /etc/xdg/autostart/nm-applet.desktop

#+-+-+-+-+-+-+-+
# XFCE4-NOTIFYD
#+-+-+-+-+-+-+-+

gawk -i inplace '!/OnlyShowIn/' /etc/xdg/autostart/xfce4-notifyd.desktop


# +-+-+-+-+-+-+-+-+-+-+
# MHWD-MANJARO INSTALL
# +-+-+-+-+-+-+-+-+-+-+

# cd /home/${ARCH_USER}

# mv /opt/$(basename "$MANJARO_FILE_URL") /home/${ARCH_USER}
# sudo -u ${ARCH_USER} tar -xvf $(basename "$MANJARO_FILE_URL") -C /

# cd /home/${ARCH_USER}/mhwd-manjaro/

# pacman -U ./v86d-0.1.10-6-x86_64.pkg.tar.zst --noconfirm
# pacman -U ./mhwd-amdgpu-19.1.0-1-any.pkg.tar.zst --noconfirm
# pacman -U ./mhwd-ati-19.1.0-1-any.pkg.tar.zst --noconfirm
# pacman -U ./mhwd-nvidia-390xx-390.157-6-any.pkg.tar.zst --noconfirm
# pacman -U ./mhwd-nvidia-470xx-470.182.03-2-any.pkg.tar.zst --noconfirm
# pacman -U ./mhwd-nvidia-530.41.03-4-any.pkg.tar.zst --noconfirm
# pacman -U ./mhwd-db-0.6.5-25-any.pkg.tar.zst --noconfirm
# pacman -U ./mhwd-0.6.5-25-x86_64.pkg.tar.zst --noconfirm

# cd /home/${ARCH_USER}

# rm -rf /home/${ARCH_USER}/mhwd-manjaro
# rm -f $(basename "$MANJARO_FILE_URL")

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


# +-+-+-+-+-+-+-+-+-+-+
# CLEANUP OPENBOX MENU
# +-+-+-+-+-+-+-+-+-+-+

cp -R ${ARCHBANGRETRO_FOLDER}/applications /usr/share/

cp /usr/share/applications/volumeicon.desktop /etc/xdg/autostart

rm /usr/share/applications/pcmanfm-desktop-pref.desktop
rm /usr/share/applications/avahi-discover.desktop
rm /usr/share/applications/conky.desktop
rm /usr/share/applications/tint2.desktop
rm /usr/share/applications/volumeicon.desktop
rm /usr/share/applications/qv4l2.desktop
rm /usr/share/applications/qvidcap.desktop
rm /usr/share/applications/cmake-gui.desktop
rm /usr/share/applications/gda-browser-5.0.desktop
rm /usr/share/applications/gda-control-center-5.0.desktop
rm /usr/share/applications/bssh.desktop
rm /usr/share/applications/bvnc.desktop
rm /usr/share/applications/nitrogen.desktop
rm /usr/share/applications/lxinput.desktop
rm /usr/share/applications/vim.desktop
rm /usr/share/applications/gmrun.desktop
rm /usr/share/applications/assistant.desktop
rm /usr/share/applications/designer.desktop
rm /usr/share/applications/linguist.desktop
rm /usr/share/applications/qdbusviewer.desktop
rm /usr/share/applications/lstopo.desktop
rm /usr/share/applications/org.gnome.Shotwell-Profile-Browser.desktop
rm /usr/share/applications/org.gnome.Shotwell-Viewer.desktop

EOF

#
# DONE
#

echo ""
echo "INSTALLATION COMPLETED SUCCESSFULLY !"
echo ""
