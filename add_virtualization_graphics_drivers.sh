#!/bin/bash

# Define the modules to be added
MODULES_TO_ADD=(
    "vmwgfx"      # VMware's virtual GPU
    "hyperv_drm"  # Hyper-V framebuffer driver
    "virtio_gpu"  # Virtio GPU for QEMU/KVM
    "qxl"         # QEMU's QXL video driver
    "vboxvideo"   # VirtualBox
)

# Backup the original mkinitcpio.conf
cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak

# Read the current MODULES array
CURRENT_MODULES=$(grep '^MODULES=' /etc/mkinitcpio.conf)

# Remove the 'MODULES=' part and any surrounding parentheses
CURRENT_MODULES=${CURRENT_MODULES#MODULES=}
CURRENT_MODULES=${CURRENT_MODULES#(}
CURRENT_MODULES=${CURRENT_MODULES%)}

# Convert the string to an array
IFS=' ' read -r -a CURRENT_MODULES_ARRAY <<< "$CURRENT_MODULES"

# Add new modules if they are not already present
for MODULE in "${MODULES_TO_ADD[@]}"; do
    if [[ ! " ${CURRENT_MODULES_ARRAY[@]} " =~ " ${MODULE} " ]]; then
        CURRENT_MODULES_ARRAY+=("$MODULE")
    fi
done

# Convert the array back to a space-separated string
NEW_MODULES_STRING="${CURRENT_MODULES_ARRAY[*]}"

# Update the mkinitcpio.conf file with the new MODULES array
sed -i "s|^MODULES=.*|MODULES=(${NEW_MODULES_STRING})|" /etc/mkinitcpio.conf

# Regenerate the initramfs for all installed kernels
mkinitcpio -P

echo "Virtualization graphics drivers have been added and initramfs regenerated."

