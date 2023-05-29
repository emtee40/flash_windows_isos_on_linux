# What this script do?
It creates a bootable Windows USBs using the UEFI:NTFS bootloader created by pbatard.

It should work on all distros. I have tested it on Debian 11. 

D3ENNY, who can be found at https://github.com/D3ENNY, is working on a better solution to manage the dependencies on Arch Linux and Fedora.

# How to use ?

| Usage                                | Description                                                |
|--------------------------------------|------------------------------------------------------------|
| `./script.sh <disk_name> <iso_file>` | Runs the script with the specified disk name and ISO file. |
|                
|                                      |                                                            |
| Additional parameters:               |                                                            |
| `<win11_bypass>`                     | (Optional) Skips the hardware requirements checks and the  |
|                                      | online account for Windows 11 installation.                |
|                                      | Must be provided as the third parameter.                    |
|                                      |                                                            |
| `<win10_bypass>`                     | (Optional) Skips the online account for Windows 10         |
|                                      | installation.                                              |
|                                      | Must be provided as the third parameter.                    |
|                                      |                                                            |
| `<rst>`                              | (Optional) Intel rst driver are needed for Intel 11th up to 13th Gen Platforms, they will be copied inside the root of the usb drive                                                |
|                                      | Must be provided as the fourth parameter.                   |

# Download 
           
    wget https://raw.githubusercontent.com/daboynb/flash_windows_isos_on_linux/main/win.sh && chmod +x win.sh && clear && ./win.sh -help
# Video

https://github.com/daboynb/flash_windows_isos_on_linux/assets/106079917/cd4132b2-b468-4845-adec-6df289937577

# Requisistes :

      - You need to use a USB that is at least 8GB.
