#!/bin/bash

sudo dpkg -l | grep -qw p7zip-full || sudo apt-get install p7zip-full -y

# List disks and partitions
sudo fdisk -l

# Ask for disk name
read -r -p "Enter the disk name without the partitions number (example /dev/sdx): " DEVICE

PARTITION_START="1M"
PARTITION_END="6GB"
MOUNT_DIR="/mnt"

sudo mkdir -p "/mnt/WIN"
mkdir -p ./resources

# Unmount the partitions if they are already mounted
sudo umount ${DEVICE}1
sudo umount ${DEVICE}2

# Eliminate all existing partitions
sudo sgdisk --zap-all $DEVICE

# Create the NTFS partition
sudo sgdisk --new=1:$PARTITION_START:$PARTITION_END --change-name=1:"NTFS" $DEVICE

# Inform the kernel of the changes to the partition table
sudo partprobe $DEVICE

# Format the NTFS partition
sudo mkfs.ntfs -f -L "Main Partition" "${DEVICE}1"

# Create the FAT16 partition
sudo parted -s $DEVICE mkpart primary fat16 6GB 7GB+1MB

# Inform the kernel of the changes to the partition table
sudo partprobe $DEVICE

# Format the FAT16 partition
sudo mkfs.fat -F 16 -n "FAT16" "${DEVICE}2"

# Download uefi.img
if [ -f ./resources/uefi-ntfs.img ]  
then
    sudo rm ./resources/uefi-ntfs.img
fi 

wget -P ./resources https://raw.githubusercontent.com/pbatard/rufus/master/res/uefi/uefi-ntfs.img

# dd of uefi.img
sudo dd if='./resources/uefi-ntfs.img' of="${DEVICE}2"

# Inform the kernel of the changes to the partition table
sudo partprobe $DEVICE

# Print information about the created partitions
sudo parted $DEVICE print

# Mount the win partition
sudo mount "${DEVICE}1" $MOUNT_DIR/WIN

# Copy files
read -e -p "Drag & drop your windows.iso : " file
eval file="$file"

7z x "$file" -o$MOUNT_DIR/WIN

# Wait
echo "Wait until you see completed, it will take some time.... be patient"

# Unmount the partitions 
sudo umount ${DEVICE}1
sudo umount ${DEVICE}2

# Clean
sudo rm -rf ./resources

# Done
echo "COMPLETED!"
