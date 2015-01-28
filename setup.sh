#!/bin/bash

# Validate arguments
if [ $# -eq 0 ]
then
    printf "Must provide at least one device number to set up.\n"
    printf "You may find this device number with lspci.\n"
    exit 1
fi

# Check if we're root
if [ $(id -u) != 0 ]
then
    printf "This script should be run as root.\n"
    exit 1
fi

# Create user permissions
printf "User: "
read USER_LIBVIRT
printf "Adding $USER_LIBVIRT to the libvirt group.\n"
groupadd libvirt
gpasswd --add $USER_LIBVIRT libvirt
printf "Creating polkit rule\n"
cp configs/50-org.libvirt.unix.manage.rules /etc/polkit-1/rules.d/

# Get the IOMMU group
printf "IOMMU group: "
read IOMMU_GROUP

# Set up QEMU permissions
printf "Setting up QEMU permissions in /etc/libvirt/qemu.conf\n"
cat configs/qemu.conf | sed 's/VFIOGROUP/\/dev\/vfio\/$IOMMU_GROUP/' >> \
    /etc/libvirt/qemu.conf

# Blacklist module
printf "Which module should we blacklist: "
read MODULE_BLACKLIST
echo $MODULE_BLACKLIST >> /etc/modprobe.d/blacklist.conf

# Add modules to mkinitcpio.conf
printf "\nPlease put the following into your /etc/mkinitcpio.conf file:\n"
printf "\tMODULES=\"pci-stub vfio-pci vfio_iommu_type1\"\n\n"
printf "Press return when you're done..."
read

printf "Configurations are done. Make sure to run mkinitcpio and reboot.\n"
printf "Also read the rest of the README to set up the VM.\n"
