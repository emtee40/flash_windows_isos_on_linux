#!/bin/bash

# Ask for sudo privileges
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

echo ""
echo "Checking dependencies"
echo ""
sleep 04
clear

sudo dpkg -l | grep -qw p7zip-full || sudo apt-get install p7zip-full -y

# List disks and partitions
lsblk -d -n -p -o NAME,MODEL | grep "/dev/sd"

while true; do
    echo ""
    read -r -p "Enter the disk name without the partition number (example /dev/sdx): " DEVICE

    # Only allow /dev/sda, /dev/sdb, ecc.
    if [[ $DEVICE =~ ^/dev/sd[a-z]$ ]]; then
        break
    else
        echo "Wrong format."
    fi
done

echo ""
read -r -p "Proceed? This will destroy all data on the target device. (y/n): " ANSWER

if [[ $ANSWER =~ ^[Yy]$ ]]; then
    echo ""
    echo "Proceeding with the operation..."
else
    echo "Operation aborted."
    exit 0
fi

PARTITION_START="1M"
PARTITION_END="12GB"
MOUNT_DIR="/mnt"

echo ""
echo "Creating folders"
echo ""
sleep 04
clear

sudo mkdir -p "/mnt/WIN"

echo ""
echo "Unmounting if mounted"
echo ""
sleep 04
clear

# Unmount the partitions if they are already mounted
sudo umount ${DEVICE}1
sudo umount ${DEVICE}2

echo ""
echo "Creating partitions"
echo ""
sleep 04
clear

# Eliminate all existing partitions
sudo sgdisk --zap-all $DEVICE

# Convert gpt 
sudo gdisk ${DEVICE} <<EOF
w
y
EOF

# Inform the kernel of the changes 
sudo partprobe $DEVICE

# Create the NTFS partition
sudo parted ${DEVICE} <<EOF
mklabel gpt
mkpart primary ntfs 0GB 7GB
print
quit
EOF

# Create the FAT16 partition
sudo parted ${DEVICE} <<EOF
mkpart primary fat16 7GB 7001MB
print
quit
EOF

# Format NTFS
sudo mkfs.ntfs -f -L "Main Partition" ${DEVICE}1

# Format FAT16
sudo mkfs.fat -F 16 -n "FAT16" ${DEVICE}2

# Inform the kernel of the changes 
sudo partprobe $DEVICE

echo ""
echo "Download and dd the rufus bootloader"
echo ""
sleep 04
clear

# Download uefi.img
if [ -f /tmp/uefi-ntfs.img ]  
then
    sudo rm /tmp/uefi-ntfs.img
fi 

wget -P /tmp https://raw.githubusercontent.com/pbatard/rufus/master/res/uefi/uefi-ntfs.img

# dd of uefi.img
sudo dd if='/tmp/uefi-ntfs.img' of="${DEVICE}2"

# Print information about the created partitions
sudo parted $DEVICE print

label=$(sudo blkid -o list | grep UEFI_NTFS)

if [[ -z "$tpm" ]]; then
    echo "Label is UEFI_NTFS"
else
    echo "Error, label is not UEFI_NTFS"
    echo "Operation aborted."
    exit 0
fi

# Mount the win partition
sudo mount "${DEVICE}1" $MOUNT_DIR/WIN

echo ""
echo "Copying files"
echo ""
sleep 04
clear

# Copy files
read -e -p "Drag & drop your windows.iso : " file
eval file="$file"

7z x "$file" -o$MOUNT_DIR/WIN

if [ $? -eq 0 ]; then
    echo "Extraction completed successfully."
else
    echo "Error occurred during extraction."
    echo "Operation aborted."
    exit 0
fi

sleep 04
clear
echo ""
echo "Unmounting partitions, it will takes a lot of time.... be patient"
echo ""
sleep 04

# Unmount the partitions 
sudo umount ${DEVICE}1
sudo umount ${DEVICE}2

echo ""
echo "Cleaning"
echo ""
sleep 04
clear

# Clean
sudo rm -rf '/mnt/WIN' 

# Done
echo "COMPLETED! BYE"
