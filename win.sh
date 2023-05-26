#!/bin/bash

win_11_unattend() {
    echo ""    
    wget -P /tmp https://raw.githubusercontent.com/daboynb/flash_windows_isos_on_linux/main/files/%24OEM%24.zip
    7z x '/tmp/$OEM$.zip' -o"$MOUNT_DIR/WIN/sources"
    echo ""
}

win_rst() {
    echo ""
    wget -P /tmp https://github.com/daboynb/flash_windows_isos_on_linux/raw/main/files/Drivers.zip
    7z x /tmp/Drivers.zip -o"$MOUNT_DIR/WIN"
    echo ""    
}

show_help() {
    echo ""
    echo "Intel rst driver are needed for Intel 11th up to 13th Gen Platforms, they will be copied inside the root of the usb drive"
    echo ""
    echo "Usage for win10 or 11 without bypass: $0 <disk_name> <iso_file>"
    echo ""
    echo "Usage for win11 with requirements bypass: $0 <disk_name> <iso_file> <win11>"
    echo ""
    echo "Usage for win10 or 11 without bypass with rst drivers: $0 <disk_name> <iso_file> <rst>"
    echo ""
    echo "Usage for win11 with requirements bypass and rst drivers: $0 <disk_name> <iso_file> <win11> <rst>"
    echo ""
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -help)
            show_help
            exit 0
            ;;
        *)
            break
            ;;
    esac

    shift
done

# Validate the number of command-line arguments
if [ "$#" -lt 2 ]; then
    echo ""
    echo "Type -help for the help"
    echo ""
    exit 1
fi

DEVICE="$1"
ISO_FILE="$2"
WIN11_OPTION="$3"
RST="$4"

clear
echo ""
echo "Disk: $DEVICE"
echo "ISO File: $ISO_FILE"
if [[ -n "$WIN11_OPTION" ]]; then
    echo "Win 10/11: $WIN11_OPTION"
fi
if [[ -n "$RST" ]]; then
    echo "$RST yes"
fi
echo ""

# Check if the device exists
if [ ! -e "$DEVICE" ]; then
    echo "Device $DEVICE does not exist."
    exit 1
fi

# Check if the ISO file exists
if [ ! -f "$ISO_FILE" ]; then
    echo "ISO file $ISO_FILE does not exist."
    exit 1
fi

# Check for sudo privileges
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

clear
echo ""
echo "Checking dependencies"
echo ""
sleep 4

sudo dpkg -l | grep -qw p7zip-full || sudo apt-get install p7zip-full -y

if [ $? -eq 1 ]; then
    echo "Installation of p7zip-full failed."
    exit 1
fi

# Confirm the operation with the user
echo ""

while [ -z $prompt ];
do read -p "Proceed? This will destroy all data on the target device. (y/n): " choice;
case "$choice" in
    y|Y ) echo "Start!";break;;
    n|N ) exit 1;;
esac;
done;

PARTITION_START="1M"
PARTITION_END="12GB"
MOUNT_DIR="/mnt"

clear
echo ""
echo "Creating folder"
echo ""
sleep 4

sudo mkdir -p "$MOUNT_DIR/WIN"

clear
echo ""
echo "Unmounting if mounted"
echo ""
sleep 4

# Unmount the partitions if they are already mounted
sudo umount "${DEVICE}1"
sudo umount "${DEVICE}2"

clear
echo ""
echo "Creating partitions"
echo ""
sleep 4

# Eliminate all existing partitions
sudo sgdisk --zap-all "$DEVICE"

# Convert gpt
sudo gdisk "$DEVICE" <<EOF
w
y
EOF

# Inform the kernel of the changes
sudo partprobe "$DEVICE"

# Create the NTFS partition
sudo parted "$DEVICE" <<EOF
mklabel gpt
mkpart primary ntfs 0GB 7GB
print
quit
EOF

# Inform the kernel of the changes
sudo partprobe "$DEVICE"

# Create the FAT16 partition
sudo parted "$DEVICE" <<EOF
mkpart primary fat16 7GB 7001MB
print
quit
EOF

# Inform the kernel of the changes
sudo partprobe "$DEVICE"

# Format NTFS
sudo mkfs.ntfs -f -L "Main Partition" "${DEVICE}1"

# Check for NTFS with "Main Partition" label
label=$(sudo blkid -o list | awk '/Main Partition/ && /ntfs/ {print $3}')

if [[ -n "$label" ]]; then
    echo "Label 'Main Partition' found for NTFS partition"
    sleep 4
else
    echo "Error, label 'Main Partition' not found for NTFS partition"
    echo "Operation aborted."
    exit 1
fi

# Inform the kernel of the changes
sudo partprobe "$DEVICE"

clear
echo ""
echo "Download and dd the rufus bootloader"
echo ""
sleep 4

# Download uefi.img
if [ -f /tmp/uefi-ntfs.img ]; then
    sudo rm /tmp/uefi-ntfs.img
fi

wget -P /tmp https://raw.githubusercontent.com/pbatard/rufus/master/res/uefi/uefi-ntfs.img

# dd of uefi.img
sudo dd if='/tmp/uefi-ntfs.img' of="${DEVICE}2"

# Inform the kernel of the changes
sudo partprobe "$DEVICE"

# Print information about the created partitions
sudo parted "$DEVICE" print

# Check for FAT16 with "UEFI_NTFS" label
label=$(sudo blkid -o list | awk '/UEFI_NTFS/ && /vfat/ {print $3}')

if [[ -n "$label" ]]; then
    echo "Label 'UEFI_NTFS' found for FAT16 partition"
    sleep 4
else
    echo "Error, label 'UEFI_NTFS' not found for FAT16 partition"
    echo "Operation aborted."
    exit 1
fi

# Mount the win partition
sudo mount "${DEVICE}1" "$MOUNT_DIR/WIN"

clear
echo ""
echo "Copying files"
echo ""
sleep 4

# Copy files
7z x "$ISO_FILE" -o"$MOUNT_DIR/WIN"

if [ $? -eq 0 ]; then
    echo "Extraction completed successfully."
else
    echo "Error occurred during extraction."
    echo "Operation aborted."
    exit 1
fi

# win_11_unattend function 
if [ "$WIN11_OPTION" = "win11" ]; then
    win_11_unattend
fi

# win_rst function 
if [ "$RST" = "rst" ]; then
    win_rst
fi

sleep 4
clear
echo ""
echo "Syncing data... be patient"
echo ""
sleep 4

# Sync data
sync

sleep 4
clear
echo ""
echo "Unmounting partitions... be patient"
echo ""
sleep 4

# Unmount the partitions
sudo umount "${DEVICE}1"
sudo umount "${DEVICE}2"

clear
echo ""
echo "Cleaning"
echo ""
sleep 4

# Clean
sudo rm -rf "$MOUNT_DIR/WIN"
sudo rm /tmp/uefi-ntfs.img
sudo rm '/tmp/$OEM$.zip'
sudo rm /tmp/Drivers.zip

# Done
echo "COMPLETED! BYE"