#!/bin/bash

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# NEED TO BE RAN WITH ADMIN PRIVILEGES
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

if [ "$EUID" -ne 0 ]
  then
    printf "\n${CYAN}This script needs to be ran with admin privileges to execute properly.\n\n${NC}"
  exit
fi

# Check if the SETTINGS file exists, exit if not as it is essential for 
# the script to succeed.

if [ -e "./SETTINGS" ]; then
    source "./SETTINGS"
else
    echo "Error: SETTINGS file not found. Please make sure the file exists."
    exit 1
fi

# +-+-+-+
#  MAIN 
# +-+-+-+

# Inserts [aurbin] before [core] to make sure the modified
# systemd package is installed from aurbin.

sed -i '0,/#Include = \/etc\/pacman.d\/mirrorlist/ { /#Include = \/etc\/pacman.d\/mirrorlist/a \
\
[aurbin]\
SigLevel = Optional TrustAll\
Server = https:\/\/github.com\/Mordillo98\/aurbin\/raw\/master\/\
}
}' /etc/pacman.conf

# For esthetics remove one line afterwards.
sed -i '/Server = https:\/\/github.com\/Mordillo98\/aurbin\/raw\/master\//{n;d;}' /etc/pacman.conf
