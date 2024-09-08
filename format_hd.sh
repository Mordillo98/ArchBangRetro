#!/bin/bash

source ./SETTINGS


function make_swap_size() {
  echo "Fetching memory information from /proc/meminfo..."

  # Use /proc/meminfo to get total physical memory size in KiB
  meminfo=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  echo "Total physical memory (KiB): $meminfo"

  if [ -z "$meminfo" ]; then
    echo "Failed to extract physical memory sizes. Exiting..."
    exit 1
  fi

  # Convert KiB to MiB, rounding up, and add 1 to determine swap size
  SWAP_SIZE=$(( (meminfo / 1024) + 1 ))

  # Convert to KiB for parted
  SWAP_SIZE=$((SWAP_SIZE * 1024))

  echo "Calculated swap size (KiB): $SWAP_SIZE"
}

make_swap_size


# Unmount /mnt if mounted
if mount | grep /mnt > /dev/null; then
  umount -R /mnt
fi

# Wipe filesystem signatures on the drive
wipefs -a $DRIVE --force

# Partition the disk
if [ "${FIRMWARE}" = "BIOS" ]; then
  parted -a optimal $DRIVE --script mklabel msdos
  parted -a optimal $DRIVE --script unit mib

  parted -a optimal $DRIVE --script mkpart primary 1 1025
  parted -a optimal $DRIVE --script set 1 boot on

  # Calculate end of swap partition by adding swap size to start of swap partition
  END_OF_SWAP=$((1025 + SWAP_SIZE / 1024))  # Convert SWAP_SIZE back to MiB for calculation

  parted -a optimal $DRIVE --script mkpart primary 1025 $END_OF_SWAP
  parted -a optimal $DRIVE --script mkpart primary $END_OF_SWAP -- -1

else  # For UEFI systems
  parted -a optimal $DRIVE --script mklabel gpt
  parted -a optimal $DRIVE --script unit mib

  parted -a optimal $DRIVE --script mkpart primary 1 1025
  parted -a optimal $DRIVE --script name 1 boot
  parted -a optimal $DRIVE --script set 1 boot on

  END_OF_SWAP=$((1025 + SWAP_SIZE / 1024))  # Convert SWAP_SIZE back to MiB for calculation

  parted -a optimal $DRIVE --script mkpart primary 1025 $END_OF_SWAP
  parted -a optimal $DRIVE --script name 2 swap

  parted -a optimal $DRIVE --script mkpart primary $END_OF_SWAP -- -1
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
