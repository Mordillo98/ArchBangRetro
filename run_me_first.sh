#!/bin/bash

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# NEED TO BE RAN WITH ADMIN PRIVILEGES
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

if [ "$EUID" -ne 0 ]
  then
    printf "\n${CYAN}This script needs to be ran with admin privileges to execute properly.\n\n"
    exit
fi

# +-+-+-+-+-+-
# COLOR CODES
# +-+-+-+-+-+-

BLUE='\033[1;34m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BCK_RED='\033[1;41m'
NC='\033[0m'

clear

printf "\n\n"

if [ "$(mount | grep -o "/ramdrv")" != "/ramdrv" ]; then
printf "${YELLOW}Creating /ramdrv...${BLUE}\n\n"
  mkdir -p /ramdrv
  mount -t ramfs -o size=10M ramfs /ramdrv > /dev/null 2>&1
  chown -R $(whoami):$(whoami) /ramdrv
  else printf "${CYAN}/ramdrv already created${BLUE}\n\n"
fi

mount | grep /ramdrv

printf "\n${GREEN}Copying files into /ramdrv\n"
cp ./archbangretroinstall.sh /ramdrv/ || exit 1
cp SETTINGS /ramdrv/ || exit 1

printf "\n\n${WHITE}Enjoy the speed !\n\n${NC}"

/ramdrv/archbangretroinstall.sh

