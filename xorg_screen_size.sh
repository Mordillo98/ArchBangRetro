#!/bin/bash

# Format the date as [YYYY-MM-DD HH:MM:SS]
FORMATTED_DATE=$(date +"[%Y-%m-%d %H:%M:%S]")

# Define the path to slim.service
SERVICE_FILE="/usr/lib/systemd/system/slim.service"

# Check if either of the configuration files exist
DIRECTORY="/etc/X11/xorg.conf.d/"
FILE1="10_1080p.conf"
FILE2="10_720p.conf"

if [ -e "${DIRECTORY}${FILE1}" ] || [ -e "${DIRECTORY}${FILE2}" ]; then
  echo "One or both files exist. Removing ExecStartPre from slim.service and exiting script."
  # Remove the ExecStartPre line from slim.service using sed
  sudo sed -i '/ExecStartPre=\/opt\/archbangretro\/scripts\/xorg_screen_size.sh/d' $SERVICE_FILE
  systemctl daemon-reload
  exit
fi

# Continue with the rest of your script

echo "Files do not exist. Continuing script execution..."

# Save the current DISPLAY value
ORIGINAL_DISPLAY=$DISPLAY

# Check if xrandr is installed
if ! command -v xrandr &> /dev/null
then
    echo "xrandr could not be found. Attempting to install..."

    # Update the package database and install xorg-xrandr
    yes | pacman -Sy xorg-xrandr --noconfirm

    # Check if the installation was successful
    if command -v xrandr &> /dev/null
    then
        echo "xrandr has been successfully installed."
    else
        echo "Failed to install xrandr. Please check your permissions or package name."
    fi
else
    echo "xrandr is already installed."
fi

# Check if xorg is installed
if ! command -v xorg-server &> /dev/null
then
    echo "xorg-server could not be found. Attempting to install..."

    # Update the package database and install xorg-xrandr
    yes | pacman -Sy xorg-server --noconfirm

    # Check if the installation was successful
    if command -v xorg-server &> /dev/null
    then
        echo "xorg-server has been successfully installed."
    else
        echo "Failed to install xorg-server. Please check your permissions or package name."
    fi
else
    echo "xorg-server is already installed."
fi


# Start Xorg on a new virtual display (e.g., :1)
Xorg :1 &
XORG_PID=$!

# Wait a bit for Xorg to start up
sleep 2

# Export the DISPLAY variable so xrandr knows which X server to talk to
export DISPLAY=:1

# Check if 1080p resolution is available
if xrandr | grep "1920x1080" > /dev/null; then
    echo "1080p resolution is available."

    # Define the configuration to enforce 1080p resolution
    conf1080p="Section \"Screen\"
    Identifier \"Screen0\"
    Device \"Device0\"
    Monitor \"Monitor0\"
    DefaultDepth 24
    SubSection \"Display\"
        Modes \"1920x1080\"
    EndSubSection
EndSection"

    # Check if /etc/X11/xorg.conf.d/ directory exists, if not create it
    if [ ! -d "${DIRECTORY}" ]; then
        sudo mkdir -p ${DIRECTORY}
    fi

    # Create the 10_1080p.conf file
    echo "$conf1080p" | sudo tee ${DIRECTORY}${FILE1} > /dev/null

    echo "10_1080p.conf has been created."
    printf "${FORMATTED_DATE}  10_1080p file created\n" >> ${DIRECTORY}trace.log
 

 # Check if 720p resolution is available if 1080p is not
 elif xrandr | grep "1280x720" > /dev/null; then
    echo "720p resolution is available."

    # Define the configuration to enforce 720p resolution
    conf720p="Section \"Screen\"
    Identifier \"Screen0\"
    Device \"Device0\"
    Monitor \"Monitor0\"
    DefaultDepth 24
    SubSection \"Display\"
        Modes \"1280x720\"
    EndSubSection
EndSection"

    # Check if /etc/X11/xorg.conf.d/ directory exists, if not create it
    if [ ! -d "${DIRECTORY}" ]; then
        sudo mkdir -p ${DIRECTORY}
    fi

    # Create the 10_720p.conf file
    echo "$conf720p" | sudo tee ${DIRECTORY}${FILE2} > /dev/null

    echo "10_720p.conf has been created."
    printf "${FORMATTED_DATE}  10_720p file created\n" >> ${DIRECTORY}trace.log
else
    echo "Neither 1080p nor 720p resolution is available."
    printf "${FORMATTED_DATE}  Neither 1080p or 720p was available\n" >> ${DIRECTORY}trace.log
fi

# Kill the Xorg process
kill $XORG_PID

# Wait to ensure the process has been terminated
wait $XORG_PID 2>/dev/null

# Restore the original DISPLAY value
export DISPLAY=$ORIGINAL_DISPLAY

# Return to the original terminal
chvt 1
