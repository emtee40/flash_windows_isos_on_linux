#!/bin/bash

# Check for sudo privileges
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

########################## Dependencies check ##########################
clear
echo ""
echo "Checking dependencies"
echo ""
sleep 4

# Check if some programs are installed
programs=("wget" "sgdisk" "gdisk" "partprobe" "parted" "mkfs.ntfs" "blkid" "lsblk")

for program in "${programs[@]}"; do
    if sudo which "$program" >/dev/null 2>&1; then
        echo "$program is installed"
    else
        echo "$program is not installed"
        sleep 10
        exit 1
    fi
done

# Declare functions
install_arch_linux_dependencies() {
    printf "\n\n============\nInstalling Arch Linux dependencies...\n============\n\n"
    sudo pacman -S p7zip --noconfirm
    check_installation_status 
}

install_debian_dependencies() {
    printf "\n\n============\nInstalling Debian-based dependencies...\n============\n\n"
    sudo apt install -y p7zip-full 
    check_installation_status 
}

install_fedora_dependencies() {
    printf "\n\n============\nInstalling Fedora-based dependencies...\n\n"
    sudo dnf install -y p7zip p7zip-plugins 
    check_installation_status 
}

# Check installation result
check_installation_status() {

    if [ $? -eq 1 ]; then
        echo "Installation of p7zip failed."
        exit 1
    fi

}

# Check which distro are you using
if command -v pacman &>/dev/null; then
    install_arch_linux_dependencies
elif command -v apt-get &>/dev/null; then
    install_debian_dependencies
elif command -v dnf &>/dev/null; then
    install_fedora_dependencies
else
    echo "Unknown distro"
    exit 1
fi

clear

########################## End of dependencies check ##########################

########################## Usb partitioning ##########################

# Function to list USB devices
list_usb_devices() {
  lsblk -d -n -p -o NAME,MODEL | grep "/dev/sd"
}

while true; do
# Get USB device list with numbers using awk
usb_devices_list=$(list_usb_devices | awk '{print NR, $0}')

# Print the numbered list
echo "List of connected USB devices:"
echo "$usb_devices_list"

# Ask the user to choose a device by number
  read -p "Enter the number of the USB device you want to select: " chosen_number

  # Extract the selected USB device name using awk
  DEVICE=$(echo "$usb_devices_list" | awk -v chosen="$chosen_number" '$1 == chosen {print $2}')

  # Check if the user input is valid
  if [ -z "$DEVICE" ]; then
    echo "Invalid choice. Please enter a valid number from the list."
    sleep 4
    clear
  else
    break
  fi
done

echo "You have chosen: $DEVICE"

# Check usb size
disk_size=$(lsblk -b "$DEVICE" | grep "disk" | awk '{print $4/1024/1024/1024}')
if (( $(echo "$disk_size < 8" | bc -l) )); then
    echo "Disk size is less than 8 GB."
    exit 1
fi

# Confirm the operation with the user
clear
echo ""

while [ -z $prompt ];
do read -p "Proceed? This will destroy all data on the target device. (y/n): " choice;
case "$choice" in
    y|Y ) echo "Start!";break;;
    n|N ) exit 1;;
esac;
done;

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

########################## End of usb partitioning ##########################

########################## Iso extraction ##########################

# Mount the win partition
sudo mount "${DEVICE}1" "$MOUNT_DIR/WIN"

# Select iso file
clear
echo ""
while true; do
  echo ""
  read -e -p "Drag & drop your Windows ISO file: " ISO_FILE
  eval ISO_FILE="$ISO_FILE"

  if [[ -f "$ISO_FILE" && "$ISO_FILE" == *.iso ]]; then
    echo "You have selected a valid ISO file: $ISO_FILE"
    break
  else
    echo "Invalid selection. Please make sure to choose a valid Windows ISO file."
  fi
done

clear
echo ""
echo "Copying files"
echo ""
sleep 4

# Copy files
extract_on_arch() {
    7z x "$ISO_FILE" -o"$MOUNT_DIR/WIN"
}

extract_on_debian() {
    7z x "$ISO_FILE" -o"$MOUNT_DIR/WIN"
}

extract_on_fedora() {
    7za x "$ISO_FILE" -o"$MOUNT_DIR/WIN"
}

# Check which distro are you using
if command -v pacman &>/dev/null; then
    extract_on_arch
elif command -v apt-get &>/dev/null; then
    extract_on_debian
elif command -v dnf &>/dev/null; then
    extract_on_fedora
else
    echo "Unknown distro"
    exit 1
fi

if [ $? -eq 0 ]; then
    echo "Extraction completed successfully."
else
    echo "Error occurred during extraction."
    echo "Operation aborted."
    exit 1
fi

clear

########################## End of iso extraction ##########################

########################## Iso image options ##########################

# Function to handle win 11 unattend.xml
win_11_unattend() {
    echo ""    
    wget -P /tmp 'https://github.com/daboynb/flash_windows_isos_on_linux/raw/main/files/$OEM$11.zip'
    7z x '/tmp/$OEM$11.zip' -o"$MOUNT_DIR/WIN/sources"
          
    while true; do
    read -p "Enter the Windows username, (letters only) do not use accents: " winusername
        if [[ "$winusername" =~ ^[a-zA-Z[:space:]]+$ && ! "$winusername" =~ [òàùè] ]]; then
            break
        else
        echo "Invalid username. Please enter only letters, do not use accents."
        fi
    done
    
    sed -i "s/admin/$winusername/g" '/mnt/WIN/sources/$OEM$/$$/Panther/unattend.xml' 
    echo ""
}

# Function to handle win10 unattend.xml
win_10_unattend() {
    echo ""    
    wget -P /tmp 'https://github.com/daboynb/flash_windows_isos_on_linux/raw/main/files/$OEM$10.zip'
    7z x '/tmp/$OEM$10.zip' -o"$MOUNT_DIR/WIN/sources"
          
    while true; do
    read -p "Enter the Windows username, (letters only) do not use accents: " winusername
        if [[ "$winusername" =~ ^[a-zA-Z[:space:]]+$ && ! "$winusername" =~ [òàùè] ]]; then
            break
        else
        echo "Invalid username. Please enter only letters, do not use accents."
        fi
    done
    
    sed -i "s/admin/$winusername/g" '/mnt/WIN/sources/$OEM$/$$/Panther/unattend.xml' 
    echo ""
}

# Function that asks if the user wants the unattend.xml
select_unattend_option() {
  read -p "Do you want to bypass requisites? (For Windows 10: online account; For Windows 11: hardware requirements and online account) (yes/no): " UNATTEND_OPTION

  case "$UNATTEND_OPTION" in
    [Yy]|[Yy][Ee][Ss])
      echo "You chose to use unattend."
      select_windows_version
      ;;
    [Nn]|[Nn][Oo])
      echo "You chose not to use unattend."
      ;;
    *)
      echo "Invalid choice. Please enter either 'yes' or 'no'."
      select_unattend_option
      ;;
  esac
}

# Function to select Windows version 
select_windows_version() {
  read -p "Is this Windows 10 or 11? (10/11): " WINDOWS_VERSION

  case "$WINDOWS_VERSION" in
    10)
      win_10_unattend
      ;;
    11)
      win_11_unattend
      ;;
    *)
      echo "Invalid choice. Please enter either '10' or '11'."
      select_windows_version
      ;;
  esac
}

# Bypass
select_unattend_option

# Rst drivers
echo ""
echo "Downloading rst drivers"
echo ""
wget -P /tmp 'https://github.com/daboynb/flash_windows_isos_on_linux/raw/main/files/Drivers.zip'
echo ""
echo "Copying rst drivers"
echo ""
7z x /tmp/Drivers.zip -o"$MOUNT_DIR/WIN"
echo ""   
echo "Done"
echo ""
clear 

########################## End of iso image options ##########################

########################## Sync and clean ##########################

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

if [ -f '/tmp/$OEM$10.zip' ]  
then
    sudo rm '/tmp/$OEM$10.zip'
fi

if [ -f '/tmp/$OEM$11.zip' ]  
then
    sudo rm '/tmp/$OEM$11.zip'
fi

if [ -f '/tmp/Drivers.zip' ]  
then
    sudo rm /tmp/Drivers.zip
fi

clear

# Done
echo "COMPLETED! BYE"

########################## End of sync and clean ##########################