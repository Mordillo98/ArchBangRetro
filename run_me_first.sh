# +-+-+-+-+-+-+-+-+-+-+-+-+-+-
# YES_OR_NO (question, default answer)
# =========
#
# Ask a yes or no question.
# $1: Question
# $2: Default answer (Y or N)
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-

function yes_or_no {

   QUESTION=$1
   DEFAULT_ANSWER=$2
   DEFAULT_ANSWER=${DEFAULT_ANSWER^^}
  
   Y_N_ANSWER=""
   until [ "$Y_N_ANSWER" == Y ] || [ "$Y_N_ANSWER" == N ]; do

      yn=""
 
      printf "${QUESTION}"
      if [ ${DEFAULT_ANSWER} == "Y" ]
        then
	  printf " ${WHITE}[Y/n]: ${NC}"
          read yn
        else
	  printf " ${WHITE}[y/N]: ${NC}"
          read yn
      fi

      if [ "$yn" == "" ]
        then Y_N_ANSWER=$DEFAULT_ANSWER
      fi

      case $yn in
         [Yy]*) Y_N_ANSWER="Y" ;;
         [Nn]*) Y_N_ANSWER="N" ;;
      esac

   done

   Y_N_ANSWER=${Y_N_ANSWER^^}

}

# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
# NEED TO BE RAN WITH ADMIN PRIVILEGES
# +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

if [ "$EUID" -ne 0 ]
  then
    printf "\n${CYAN}This script needs to be ran with admin privileges to execute properly.\n"

  yes_or_no "${YELLOW}Would you like to run it again with the SUDO command?${NC}" "y"

  case $Y_N_ANSWER in
    [Yy]* ) printf "${NC}"; sudo ./run_me_first.sh; exit;;
    [Nn]* ) printf "\n${CYAN}Bye bye...\n\n${NC}"; exit;;
  esac

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

printf "\n${WHITE}Copying files into /ramdrv\n\n"
cp ./archbangretroinstall.sh /ramdrv/ || exit 1
cp SETTINGS /ramdrv/ || exit 1
cd /ramdrv

printf "${YELLOW}executing archbanretroinstall.sh${NC}\n\n"
./archbangretroinstall.sh
