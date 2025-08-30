#!/bin/bash
# RadiateOS Disk Installation Script

echo "RadiateOS Installer"
echo "==================="
echo ""
echo "This will install RadiateOS to your hard drive."
echo "WARNING: This will erase all data on the selected disk!"
echo ""

# List available disks
echo "Available disks:"
lsblk -d -o NAME,SIZE,MODEL

echo ""
read -p "Enter target disk (e.g., sda): " target_disk

if [[ ! -b "/dev/$target_disk" ]]; then
    echo "Error: Disk /dev/$target_disk not found"
    exit 1
fi

echo ""
echo "You selected: /dev/$target_disk"
read -p "Are you ABSOLUTELY sure? Type 'yes' to continue: " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Installation cancelled"
    exit 1
fi

echo "Installing RadiateOS..."

# Partition the disk
parted /dev/$target_disk mklabel gpt
parted /dev/$target_disk mkpart primary ext4 1MiB 100%

# Format
mkfs.ext4 /dev/${target_disk}1

# Mount
mkdir -p /mnt/radiateos
mount /dev/${target_disk}1 /mnt/radiateos

# Copy files
cp -r /System /mnt/radiateos/
cp -r /Applications /mnt/radiateos/
cp -r /Boot /mnt/radiateos/

# Install bootloader
grub-install --target=x86_64-efi --efi-directory=/mnt/radiateos/boot /dev/$target_disk
cp /Boot/grub.cfg /mnt/radiateos/boot/grub/

echo "Installation complete!"
echo "Remove USB and reboot to start RadiateOS"
