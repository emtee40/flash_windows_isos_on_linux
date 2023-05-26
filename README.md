# What this script do?
It creates a bootable Windows USBs using the UEFI:NTFS bootloader created by pbatard.

# How to use ?

| Usage                                                       | Description                                                                         |
|-------------------------------------------------------------|-------------------------------------------------------------------------------------|
| `./win.sh <disk_name> <iso_file>`                            | For installing Windows 10 or 11 without bypassing any requirements.            |
| `./win.sh <disk_name> <iso_file> <win11>`                    | For installing Windows 11 with requirements bypassed.                           |
| `./win.sh <disk_name> <iso_file> <rst>`                      | For installing Windows 10 or 11 without bypassing requirements with RST drivers.|
| `./win.sh <disk_name> <iso_file> <win11> <rst>`              | For installing Windows 11 with requirements bypassed and RST drivers.           |

Please note that <disk_name> refers to the name of the disk where you want to install Windows, and <iso_file> refers to the path or name of the Windows ISO file you want to use for installation.

# Video

https://github.com/daboynb/flash_windows_isos_on_linux/assets/106079917/cd4132b2-b468-4845-adec-6df289937577

# Requisistes :

      - You need to use a USB that is at least 8GB.
