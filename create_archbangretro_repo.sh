#!/bin/bash

# set -e  # Script must stop if there is an error.
# set -x  # debugging.

# +-+-+-+-+
# SETTINGS
# +-+-+-+-+

# Reads the SETTINGS file to define global variables.
source ./SETTINGS

# +-+-+-+-+-+-
# CREATE USER
# +-+-+-+-+-+-

printf "${NC}\n"

# Function to display prompts in yellow on the same line
prompt() {
    echo -ne "${YELLOW}$1${NC}"
}

# Check if the user exists
if id "$ARCH_USER" &>/dev/null; then
    prompt "User $ARCH_USER exists.\n"

    # Check if the user is part of the wheel group
    if groups "$ARCH_USER" | grep -q "\bwheel\b"; then
        prompt "User $ARCH_USER is already part of the wheel group.\n"
    else
        # Prompt to add user to the wheel group
        prompt "User $ARCH_USER is not in the wheel group. Add? (y/n): "
        read -r choice
        if [[ "$choice" == [Yy]* ]]; then
            usermod -aG wheel "$ARCH_USER"
            prompt "\nUser $ARCH_USER added to the wheel group.\n"
        else
            prompt "\nOperation aborted.\n"
            exit 1
        fi
    fi
else
    # Prompt to create the user
    prompt "User $ARCH_USER does not exist. Create? (y/n): "
    read -r choice
    if [[ "$choice" == [Yy]* ]]; then
        useradd -m -G wheel -s /bin/bash "$ARCH_USER"
        prompt "\nUser $ARCH_USER created and added to the wheel group.\n"
        echo "${ARCH_USER}:${USER_PSW}" | chpasswd
        prompt "Password set for $ARCH_USER.\n"
    else
        prompt "\nOperation aborted.\n"
        exit 1
    fi
fi

# Check if the sudoers file is correctly configured for the wheel group
if sudo grep -q '# %wheel ALL=(ALL:ALL) NOPASSWD: ALL' /etc/sudoers; then
    # Prompt to update sudoers file
    prompt "The wheel group does not have password-less sudo. Fix? (y/n): "
    read -r choice
    if [[ "$choice" == [Yy]* ]]; then
        sudo sed -i 's/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
        prompt "\nSudoers file updated.\n"
    else
        prompt "\nOperation aborted.\n"
        exit 1
    fi
else
    prompt "The wheel group is already configured for password-less sudo.\n"
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

if [ "$Y_N_ANSWER" == Y ]; then
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3
  exec 1>log.out 2>&1
fi

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# SHOW THE PARAMETERS ON SCREEN
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

clear
printf "\n\n${WHITE}ARCHBANGRETRO PACKAGES BUILD SCRIPT\n"
printf "===================================\n\n"
printf "${CYAN}Press Control-C to Cancel\n\n"
printf "${GREEN}ARCH_USER   = ${CYAN}${ARCH_USER}\n"
printf "${GREEN}USER_PSW    = ${CYAN}${USER_PSW}\n"
printf "${GREEN}MIRRORS COUNTRY = ${CYAN}${REFLECTOR_COUNTRY}\n\n"

printf "${GREEN}ARCHBANGRETRO_FILE_URL = ${CYAN}${ARCHBANGRETRO_FILE_URL}\n"
printf "${GREEN}MHWD_URL               = ${CYAN}${MHWD_URL}\n"
printf "${GREEN}MANJARO_GPG_URL        = ${CYAN}${MANJARO_GPG_URL}${NC}\n\n"


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

countsleep "Automatic install will start in... " 3

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# INSTALL THE NEEDED DEPENDENCIES 
# TO RUN THIS SCRIPT FROM ARCH LIVE CD
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

printf "${CYAN}Updating archlinux's repos.\n${NC}"
pacman -Sy > /dev/null

if ! pacman -Qs dmidecode > /dev/null ; then
	printf "\n\nInstalling dmidecode..."
	pacman -S dmidecode --noconfirm > /dev/null
fi

if ! pacman -Qs reflector > /dev/null ; then
	printf "\n\nInstalling reflector...\n"
	pacman -S reflector --noconfirm > /dev/null
fi

printf "\n${NC}"

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# ENABLE MIRRORS FROM $MIRROR_LINK
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

printf "${YELLOW}Setting up best mirrors from ${REFLECTOR_COUNTRY} for this live session.\n\n${NC}" 

# reflector --sort delay --score 5 --protocol https --save /etc/pacman.d/mirrorlist

# +-+-+-+-+-+-+-+-+-+-+-+-
# UPDATE THE SYSTEM CLOCK 
# +-+-+-+-+-+-+-+-+-+-+-+-

timedatectl set-ntp true

# +-+-+-+-+-+-+-+-+-+-+-
# MHWD-MANJARO DOWNLOAD
# +-+-+-+-+-+-+-+-+-+-+-

# Specify the directory where the files will be downloaded and extracted
TARGET_DIRECTORY="/mnt/"

umount /mnt >/dev/null 2>&1

mount ${ARCHBANGRETRO_REPO} ${TARGET_DIRECTORY}

# START DEBUG HERE IF NEEDED WITH    : '

#
# DEFINE SCRIPT THAT CHECKS IF THERE ARE FILE, IF SO ASK TO DELETE.
#

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

# +-+-+-+-+-+-+-+-+-+-+-+
# MHWD AND V86d DOWNLOAD
# +-+-+-+-+-+-+-+-+-+-+-+

EXTRACTED_BIN_FOLDER="/tmp/mhwd_extracted/src/mhwd-manjaro-bin"
PARENT_DIR_MHWD="${EXTRACTED_BIN_FOLDER%/*/*}"

rm -rf ${EXTRACTED_BIN_FOLDER} >/dev/null 2>&1
mkdir -p ${EXTRACTED_BIN_FOLDER}
    
# Change the ownership
chown -R ${ARCH_USER}:${ARCH_USER} "${PARENT_DIR_MHWD}"

# Function to fetch files and count the number of occurrences
fetch_files() {
    local FILE_NAME="$1"
    local EXPECTED_COUNT="$2"
    local COUNT=0
    local DOT_COUNT=0
    local ITEMS_COUNT=0
    local UNIQUE_FILE_LIST=""
    local FILE_LIST=""

    for ((i = 1; i <= 10; i++)); do
        # Fetch the files with the given name and store in temporary file
        curl -s -m 60 "$MHWD_URL" | grep -oP "${FILE_NAME}[^\"]*\.tar\.zst" > /tmp/file_list &

        # Display dots for every 10 files until the curl command finishes
        while kill -0 $! >/dev/null 2>&1; do
            COUNT=$((COUNT + 1))

            if ((COUNT % 10 == 0)); then
                printf "."
                DOT_COUNT=$((DOT_COUNT + 1))
            fi

        sleep 0.1 # Optional: Add a short delay for visualization purposes
    done

    while read -r FILE; do

        # Append the file to the FILE_LIST variable
        FILE_LIST+=" $FILE"

    done < /tmp/file_list

        # Remove duplicate lines
        UNIQUE_FILE_LIST=$(echo "$FILE_LIST" | tr ' ' '\n' | sort | uniq)

        # Count the number of files fetched
        ITEMS_COUNT=$(echo "$UNIQUE_FILE_LIST" | wc -l)
        ITEMS_COUNT=$((ITEMS_COUNT - 1)) # because of blank line.
#        echo "Number of items: $ITEMS_COUNT"
#        echo "FILE_NAME= ${FILE_NAME}"

        # Check if the count matches the expected count
        if [ "$ITEMS_COUNT" -eq "$EXPECTED_COUNT" ]; then
            FINAL_LIST+=$UNIQUE_FILE_LIST
            rm /tmp/file_list
            return 0
        else
            sleep 1 # Optional: Add a delay before retrying
        fi
    done

    return 1
}


# Function to download and extract files
download_and_extract() {
    local FILE_NAME="$1"
    local PGP_FILE_NAME="$FILE_NAME.sig"
 
    cd ${EXTRACTED_BIN_FOLDER}

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

    echo -e "${CYAN}Extracting $FILE_NAME...${NC}"
    sudo tar -xf "$FILE_NAME" -C ${EXTRACTED_BIN_FOLDER}
    echo -e "${WHITE}Extraction completed!${NC}"

    # Clean up downloaded packages
    echo -e "${BLUE}Cleaning up downloaded packages...${NC}"
    echo
    rm -rf ${FILE_NAME}* 
    rm -rf ${PGP_FILE_NAME}*
}

printf "${YELLOW}Retrieving list of mhwd-manjaro files..."

# Fetch the HTML content of the URL and extract the file names

FINAL_LIST=""

# Start fetching mhwd files with progress indicator
fetch_files mhwd 7

# Start fetching v86d files with progress indicator
# fetch_files v86d 1

printf "\n\n"

FINAL_LIST=$(echo "$FINAL_LIST" | grep -v '^$')

# printf "\n\nFINAL_LIST= ${FINAL_LIST}\n\n"

# Loop over each line in FINAL_LIST
while IFS= read -r line; do
    download_and_extract "$line"
done <<< "$FINAL_LIST"


rm ${EXTRACTED_BIN_FOLDER}.BUILDINFO >/dev/null 2>&1
rm ${EXTRACTED_BIN_FOLDER}.INSTALL >/dev/null 2>&1
rm ${EXTRACTED_BIN_FOLDER}.PKGINFO >/dev/null 2>&1
rm ${EXTRACTED_BIN_FOLDER}.MTREE >/dev/null 2>&1

echo -e "${WHITE}All files downloaded and extracted.${NC}"

echo

cat << EOF > ${PARENT_DIR_MHWD}/PKGBUILD
# Maintainer: Martin Filion <mordillo98@gmail.com>
pkgname=mhwd-manjaro-bin
pkgname_link=mhwd-manjaro-bin
pkgbase=mhwd-manjaro-bin
pkgver=1
pkgrel=1
pkgdesc="Downloads and create mhwd files from Manjaro to install as binaries."
url="https://mirror.csclub.uwaterloo.ca/manjaro/stable/extra/x86_64/"
arch=('any')
provides=($pkgname)
conflicts=($pkgname)
depends=('hwinfo')

package() {
   cp -R \$pkgname/* \$pkgdir/
}
EOF

cd ${PARENT_DIR_MHWD}
sudo -u ${ARCH_USER} makepkg -s -f
repo-remove ${TARGET_DIRECTORY}archbangretro.db.tar.gz mhwd-manjaro-bin >/dev/null 2>&1
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./mhwd-manjaro-bin*.pkg.tar.zst
cp ./mhwd-manjaro-bin*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf ${PARENT_DIR_MHWD}

echo

exit

# +-+-+-+-
# PYTHON2
# +-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/python2-bin.git
cd /home/${ARCH_USER}/python2-bin
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./python2-bin*.pkg.tar.zst  
cp ./python2-bin*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/python2-bin

# +-+-+-+-+-+-+-+-+-+
# PYTHON2-SETUPTOOLS
# +-+-+-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} curl -fLO https://archive.archlinux.org/packages/p/python2-setuptools/python2-setuptools-2:44.1.1-2-any.pkg.tar.zst
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./python2-setuptools*.pkg.tar.zst 
cp ./python2-setuptools*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/python2-setuptools*.pkg.tar.zst 

# +-+-+-+-+
# CYTHON2
# +-+-+-+-+

export PYTHONHOME=/usr
cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/cython2.git
cd /home/${ARCH_USER}/cython2
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./cython2*.pkg.tar.zst 
cp ./cython2*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/cython2

# +-+-+-+-+-+-+-+-+-+-+-+-+-
# GNOME-ICON-THEME-SYMBOLIC (dependency for gnome-icon-theme)
# +-+-+-+-+-+-+-+-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/gnome-icon-theme-symbolic.git
cd /home/${ARCH_USER}/gnome-icon-theme-symbolic
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./gnome-icon-theme-symbolic*.pkg.tar.zst 
cp ./gnome-icon-theme-symbolic*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/gnome-icon-theme-symbolic

# +-+-+-+-+-+-+-+-+
# GNOME-ICON-THEME
# +-+-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/gnome-icon-theme.git
cd /home/${ARCH_USER}/gnome-icon-theme
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./gnome-icon-theme*.pkg.tar.zst 
cp ./gnome-icon-theme*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/gnome-icon-theme

# +-+-+
# YAY
# +-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/yay.git
cd /home/${ARCH_USER}/yay
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./yay*.pkg.tar.zst 
cp ./yay*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/yay


# +-+-+-+-+-+-
# OBMENU2-GIT
# +-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/obmenu2-git.git
cd /home/${ARCH_USER}/obmenu2-git
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./obmenu2-git*.pkg.tar.zst 
cp ./obmenu2-git*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/obmenu2-git


# +-+-+-+-+-+-
# BATTI-ICONS
# +-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/batti-icons.git
cd /home/${ARCH_USER}/batti-icons
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./batti-icons*.pkg.tar.zst 
cp ./batti-icons*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/batti-icons

# +-+-+-+-+-+-+-+-+
# OBLOGOUT-PY3-GIT
# +-+-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/oblogout-py3-git.git
cd /home/${ARCH_USER}/oblogout-py3-git
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./oblogout-py3-git*.pkg.tar.zst 
cp ./oblogout-py3-git*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/oblogout-py3-git


# +-+-+-+-+-+-+-+-+
# PYTHON2-GOBJECT2 (dependency for pygtk)
# +-+-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/python2-gobject2.git
cd /home/${ARCH_USER}/python2-gobject2
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./python2-gobject2*.pkg.tar.zst 
cp ./python2-gobject2*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/python2-gobject2

# +-+-+-+-+
# DEADBEEF
# +-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/deadbeef.git
cd /home/${ARCH_USER}/deadbeef
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./deadbeef*.pkg.tar.zst 
cp ./deadbeef*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/deadbeef

# +-+-+-+-+
# LIBGLADE
# +-+-+-+-+autoconf-archive

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} curl -fLO https://archive.archlinux.org/packages/l/libglade/libglade-2.6.4-7-x86_64.pkg.tar.zst
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./libglade*.pkg.tar.zst 
cp ./libglade*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -f libglade*.pkg.tar.zst

# +-+-+-+-+-+-+-
# PYTHON2-CAIRO (dependency for PYGTK)
# +-+-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/python2-cairo.git
cd /home/${ARCH_USER}/python2-cairo
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./python2-cairo*.pkg.tar.zst 
cp ./python2-cairo*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/python2-cairo

# +-+-+-+-+-+-+-
# PYTHON2-NUMPY (dependency for PYGTK)
# +-+-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/python2-numpy.git
cd /home/${ARCH_USER}/python2-numpy
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./python2-numpy*.pkg.tar.zst 
cp ./python2-numpy*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/python2-numpy

# +-+-+-
# PYGTK (dependency for catfish-python2 and obkey)
# +-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/pygtk.git
cd /home/${ARCH_USER}/pygtk  
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./pygtk*.pkg.tar.zst 
cp ./pygtk*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/pygtk

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-
# PYTHON2-DBUS (dependency for catfish-python2)
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/python2-dbus.git
cd /home/${ARCH_USER}/python2-dbus
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./python2-dbus*.pkg.tar.zst 
cp ./python2-dbus*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/python2-dbus

# +-+-+-
# OBKEY 
# +-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/obkey.git
cd /home/${ARCH_USER}/obkey 
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./obkey*.pkg.tar.zst 
cp ./obkey*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/obkey

# +-+-+-+
# DMENU2 
# +-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/dmenu2.git
cd /home/${ARCH_USER}/dmenu2
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./dmenu2*.pkg.tar.zst 
cp ./dmenu2*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/dmenu2


# +-+-+-+-+-+-+-+-
# GNOME-CARBONATE
# +-+-+-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/gnome-carbonate.git
cd /home/${ARCH_USER}/gnome-carbonate  
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./gnome-carbonate*.pkg.tar.zst 
cp ./gnome-carbonate*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/gnome-carbonate

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-
# GNOME-COLORS-ICON-THEME-BIN
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/gnome-colors-icon-theme-bin.git
cd /home/${ARCH_USER}/gnome-colors-icon-theme-bin
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./gnome-colors-icon-theme-bin*.pkg.tar.zst 
cp ./gnome-colors-icon-theme-bin*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/gnome-colors-icon-theme-bin

# +-+-+-+-+- 
# WALLPAPER
# +-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/archbangretro-wallpaper.git
cd /home/${ARCH_USER}/archbangretro-wallpaper
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./archbangretro-wallpaper*.pkg.tar.zst 
cp ./archbangretro-wallpaper*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/archbangretro-wallpaper


# +-+-+-+-+-+-+-
# OPENBOX-MENU
# +-+-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/openbox-menu.git
cd /home/${ARCH_USER}/openbox-menu
sudo -u ${ARCH_USER} makepkg -s -f
repo-remove ${TARGET_DIRECTORY}archbangretro.db.tar.gz openbox-menu >/dev/null 2>&1
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./openbox-menu*.pkg.tar.zst
cp ./openbox-menu*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/openbox-menu


# +-+-+-+
# FBXKB 
# +-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/fbxkb.git
cd /home/${ARCH_USER}/fbxkb
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./fbxkb*.pkg.tar.zst
cp ./fbxkb*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/fbxkb

# +-+-+-+-+-+-+-+
# OPENBOX-THEMES 
# +-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/openbox-themes.git
cd /home/${ARCH_USER}/openbox-themes
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./openbox-themes*.pkg.tar.zst
cp ./openbox-themes*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/openbox-themes

# +-+-+-+-
# ARCHBEY
# +-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/archbey.git
cd /home/${ARCH_USER}/archbey
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./archbey*.pkg.tar.zst
cp ./archbey*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/archbey


# +-+-+-+-+
# EPDFVIEW
# +-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} curl -fLO https://archive.archlinux.org/packages/e/epdfview/epdfview-0.1.8-11-x86_64.pkg.tar.zst 
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./epdfview*.pkg.tar.zst
cp ./epdfview*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -f epdfview*.pkg.tar.zst


# +-+-+-+-+-+-+-+
# MADPABLO-THEME
# +-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/madpablo-theme.git
cd /home/${ARCH_USER}/madpablo-theme
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./madpablo-theme*.pkg.tar.zst
cp ./madpablo-theme*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/madpablo-theme

# +-+-+-+-+-+-+-+
# FLAT-REMIX-GTK
# +-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/flat-remix-gtk.git
cd /home/${ARCH_USER}/flat-remix-gtk
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./flat-remix-gtk*.pkg.tar.zst
cp ./flat-remix-gtk*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/flat-remix-gtk


# +-+-+-+-+-+-+-+-+-+
# HARDINFO-GIT
# +-+-+-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/hardinfo-git.git
cd /home/${ARCH_USER}/hardinfo-git
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./hardinfo-git*.pkg.tar.zst
cp ./hardinfo-git*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/hardinfo-git


# +-+-+-+-+-+-+-+-+-+-+-+-+
# GNOME-DISK-UTILITY-3.4.1
# +-+-+-+-+-+-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
mkdir gnome-disk-utility-3.4.1
cd /home/${ARCH_USER}/gnome-disk-utility-3.4.1
curl -fLO https://sourceforge.net/projects/archbangretro/files/gnome-disk-utility-3.4.1-3.4.1-1-x86_64.pkg.tar.zst
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./gnome-disk-utility*.pkg.tar.zst
cp ./gnome-disk-utility*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/gnome-disk-utility-3.4.1

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# HTTPDIRFS (dependency for ttf-ms-win11-auto)
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/httpdirfs.git
cd /home/${ARCH_USER}/httpdirfs
sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./httpdirfs*.pkg.tar.zst
cp ./httpdirfs*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/httpdirfs

# +-+-+-+-+-+-+-+-+-
# TTF-MS-WIN11-AUTO
# +-+-+-+-+-+-+-+-+-

cd /home/${ARCH_USER}
sudo -u ${ARCH_USER} git clone https://aur.archlinux.org/ttf-ms-win11-auto.git
cd /home/${ARCH_USER}/ttf-ms-win11-auto

    #
    # PATCH NEEDED TO HAVE IT COMPILED PROPERLY.
    #

    # URL of the file to download
    url="https://sourceforge.net/projects/archbangretro/files/PKGBUILD.patch"

    # Expected MD5 checksum
    expected_md5="ac2b46cec4e42a0db6e615cc51dae25a"

    # Download the file
    curl -fLO "$url"
    chmod +x ./PKGBUILD.patch

    # Check if the download was successful
    if [ $? -eq 0 ]; then
        # Calculate the MD5 checksum of the downloaded file
        actual_md5=$(md5sum ./PKGBUILD.patch | awk '{ print $1 }')

        # Compare the actual MD5 with the expected MD5
        if [ "$actual_md5" == "$expected_md5" ]; then
            echo "MD5 checksum is correct."
        else
            echo "MD5 checksum is incorrect. Exiting."
            exit 1
        fi
    else
        echo "Failed to download the file."
        exit 1
    fi

patch ./PKGBUILD ./PKGBUILD.patch

sudo -u ${ARCH_USER} makepkg -s -f
repo-add ${TARGET_DIRECTORY}archbangretro.db.tar.gz ./ttf-ms-win11-auto*.pkg.tar.zst
cp ./ttf-ms-win11-auto*.pkg.tar.zst ${TARGET_DIRECTORY}
rm -rf /home/${ARCH_USER}/ttf-ms-win11-auto


#
# DONE
#

echo ""
echo "PACKAGES INSTALLATION COMPLETED SUCCESSFULLY !"
echo ""
