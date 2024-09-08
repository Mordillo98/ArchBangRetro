#!/bin/bash

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# NEED TO BE RAN WITH ADMIN PRIVILEGES
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

if [ "$EUID" -ne 0 ]
  then
    printf "\n${CYAN}This script needs to be ran with admin privileges to execute properly.\n\n${NC}"
  exit
fi

source ./SETTINGS

#!/bin/bash

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# NEED TO BE RAN WITH ADMIN PRIVILEGES
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

if [ "$EUID" -ne 0 ]
  then
    printf "\n${CYAN}This script needs to be ran with admin privileges to execute properly.\n\n${NC}"
  exit
fi

source ./SETTINGS

# Define the path to the pacman configuration file
PACMAN_CONF="/etc/pacman.conf"

# List of files with full paths to be excluded
EXCLUDE_FILES=(
    "usr/share/applications/volumeicon.desktop"
    "usr/share/applications/obkey.desktop"
    "usr/share/applications/pcmanfm-desktop-pref.desktop"
    "usr/share/applications/avahi-discover.desktop"
    "usr/share/applications/conky.desktop"
    "usr/share/applications/tint2.desktop"
    "usr/share/applications/volumeicon.desktop"
    "usr/share/applications/qv4l2.desktop"
    "usr/share/applications/qvidcap.desktop"
    "usr/share/applications/cmake-gui.desktop"
    "usr/share/applications/gda-browser-5.0.desktop"
    "usr/share/applications/gda-control-center-5.0.desktop"
    "usr/share/applications/bssh.desktop"
    "usr/share/applications/bvnc.desktop"
    "usr/share/applications/nitrogen.desktop"
    "usr/share/applications/lxinput.desktop"
    "usr/share/applications/vim.desktop"
    "usr/share/applications/gmrun.desktop"
    "usr/share/applications/assistant.desktop"
    "usr/share/applications/designer.desktop"
    "usr/share/applications/linguist.desktop"
    "usr/share/applications/qdbusviewer.desktop"
    "usr/share/applications/org.gnome.Shotwell-Viewer.desktop"
)

# Concatenate all paths into a single string separated by spaces
NOEXTRACT_STRING=$(printf " %s" "${EXCLUDE_FILES[@]}")
NOEXTRACT_STRING="NoExtract=${NOEXTRACT_STRING:1}"  # Remove the leading space

# Backup the original pacman.conf file
cp "$PACMAN_CONF" "${PACMAN_CONF}.bak"

# Use awk to insert NoExtract just after the [options] section and add empty lines before and after
awk -v noextract="$NOEXTRACT_STRING" '
    /^\[options\]$/ {
        print
        getline
        print ""  # Adds an empty line after [options]
        print noextract
        print ""  # Adds an empty line after the NoExtract directive
        next
    }
    { print }
' "${PACMAN_CONF}.bak" > "$PACMAN_CONF"

