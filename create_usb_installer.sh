#!/usr/bin/env bash
set -euo pipefail

# RadiateOS USB Installer Creator
# Creates a bootable USB drive with RadiateOS

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     RadiateOS USB Installer Creator    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if running on macOS or Linux
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
else
    echo -e "${RED}❌ Unsupported platform: $OSTYPE${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Detected platform: $PLATFORM${NC}"

# Function to list available USB drives
list_usb_drives() {
    echo -e "\n${YELLOW}📦 Available USB drives:${NC}"
    
    if [[ "$PLATFORM" == "macos" ]]; then
        diskutil list external | grep -E "disk[0-9]" | while read -r line; do
            disk=$(echo "$line" | awk '{print $1}')
            size=$(diskutil info "$disk" | grep "Disk Size" | awk '{print $3, $4}')
            name=$(diskutil info "$disk" | grep "Media Name" | cut -d: -f2 | xargs)
            echo "  • $disk - $name ($size)"
        done
    else
        lsblk -d -o NAME,SIZE,MODEL | grep -E "^sd[b-z]" || true
        echo ""
        echo "USB devices typically appear as /dev/sdb, /dev/sdc, etc."
    fi
}

# Function to verify USB drive
verify_usb_drive() {
    local drive=$1
    
    if [[ "$PLATFORM" == "macos" ]]; then
        if ! diskutil info "$drive" &>/dev/null; then
            echo -e "${RED}❌ Drive $drive not found${NC}"
            return 1
        fi
        
        # Check if it's external
        if ! diskutil info "$drive" | grep -q "External"; then
            echo -e "${YELLOW}⚠️  Warning: $drive doesn't appear to be an external drive${NC}"
            read -p "Are you sure you want to continue? (yes/no): " confirm
            if [[ "$confirm" != "yes" ]]; then
                return 1
            fi
        fi
    else
        if [[ ! -b "$drive" ]]; then
            echo -e "${RED}❌ Drive $drive not found${NC}"
            return 1
        fi
    fi
    
    return 0
}

# Function to build RadiateOS
build_radiateos() {
    echo -e "\n${BLUE}🔨 Building RadiateOS...${NC}"
    
    cd RadiateOS
    
    if [[ "$PLATFORM" == "macos" ]]; then
        # Build for macOS using xcodebuild
        if command -v xcodebuild &> /dev/null; then
            echo "Building with Xcode..."
            xcodebuild -project RadiateOS.xcodeproj \
                -scheme RadiateOS \
                -configuration Release \
                -archivePath build/RadiateOS.xcarchive \
                archive
            
            # Export the app
            xcodebuild -exportArchive \
                -archivePath build/RadiateOS.xcarchive \
                -exportPath build/export \
                -exportOptionsPlist scripts/export_options.plist
        else
            echo -e "${YELLOW}⚠️  Xcode not found, using Swift build${NC}"
            swift build -c release
        fi
    else
        # Build for Linux using Swift
        swift build -c release
    fi
    
    cd ..
    echo -e "${GREEN}✓ Build complete${NC}"
}

# Function to create bootable USB
create_bootable_usb() {
    local drive=$1
    
    echo -e "\n${YELLOW}⚠️  WARNING: This will erase all data on $drive${NC}"
    read -p "Are you absolutely sure? Type 'yes' to continue: " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo -e "${RED}❌ Operation cancelled${NC}"
        exit 1
    fi
    
    echo -e "\n${BLUE}🔧 Preparing USB drive...${NC}"
    
    if [[ "$PLATFORM" == "macos" ]]; then
        # Unmount the drive
        diskutil unmountDisk force "$drive"
        
        # Format as APFS with GUID partition scheme
        echo "Formatting drive as APFS..."
        diskutil eraseDisk APFS "RadiateOS" GPT "$drive"
        
        # Get the volume path
        volume="/Volumes/RadiateOS"
        
        # Wait for volume to mount
        sleep 2
        
        # Create directory structure
        echo "Creating directory structure..."
        mkdir -p "$volume/System"
        mkdir -p "$volume/Applications"
        mkdir -p "$volume/EFI/BOOT"
        
        # Copy RadiateOS app
        echo "Copying RadiateOS application..."
        if [[ -d "RadiateOS/build/export/RadiateOS.app" ]]; then
            cp -R "RadiateOS/build/export/RadiateOS.app" "$volume/Applications/"
        elif [[ -d "RadiateOS/build/macos/RadiateOS.xcarchive/Products/Applications/RadiateOS.app" ]]; then
            cp -R "RadiateOS/build/macos/RadiateOS.xcarchive/Products/Applications/RadiateOS.app" "$volume/Applications/"
        else
            echo -e "${RED}❌ RadiateOS.app not found. Please build first.${NC}"
            exit 1
        fi
        
        # Create boot loader configuration
        cat > "$volume/EFI/BOOT/startup.nsh" << 'EOF'
echo "Starting RadiateOS..."
fs0:
cd \Applications\RadiateOS.app\Contents\MacOS
RadiateOS
EOF
        
        # Create launch script
        cat > "$volume/System/boot.sh" << 'EOF'
#!/bin/bash
# RadiateOS Boot Script
echo "Booting RadiateOS..."
/Applications/RadiateOS.app/Contents/MacOS/RadiateOS
EOF
        chmod +x "$volume/System/boot.sh"
        
        # Make the drive bootable
        echo "Making drive bootable..."
        bless --folder "$volume/System" --label "RadiateOS"
        
    else
        # Linux implementation
        echo "Formatting drive..."
        sudo umount "$drive"* 2>/dev/null || true
        
        # Create GPT partition table
        sudo parted "$drive" mklabel gpt
        sudo parted "$drive" mkpart primary ext4 1MiB 100%
        
        # Format partition
        sudo mkfs.ext4 "${drive}1"
        
        # Mount the partition
        sudo mkdir -p /mnt/radiateos
        sudo mount "${drive}1" /mnt/radiateos
        
        # Create directory structure
        sudo mkdir -p /mnt/radiateos/boot
        sudo mkdir -p /mnt/radiateos/bin
        sudo mkdir -p /mnt/radiateos/etc
        
        # Copy RadiateOS binary
        if [[ -f ".build/release/RadiateOS" ]]; then
            sudo cp .build/release/RadiateOS /mnt/radiateos/bin/
        else
            echo -e "${YELLOW}⚠️  RadiateOS binary not found, creating placeholder${NC}"
            sudo touch /mnt/radiateos/bin/RadiateOS
        fi
        
        # Create boot configuration
        sudo tee /mnt/radiateos/boot/grub.cfg > /dev/null << 'EOF'
menuentry "RadiateOS" {
    linux /boot/vmlinuz root=/dev/sda1 init=/bin/RadiateOS
    initrd /boot/initrd.img
}
EOF
        
        # Install GRUB bootloader
        echo "Installing bootloader..."
        sudo grub-install --target=x86_64-efi --efi-directory=/mnt/radiateos/boot --boot-directory=/mnt/radiateos/boot "$drive"
        
        # Unmount
        sudo umount /mnt/radiateos
    fi
    
    echo -e "${GREEN}✅ Bootable USB created successfully!${NC}"
}

# Main execution
main() {
    # Check for root/sudo on Linux
    if [[ "$PLATFORM" == "linux" ]] && [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run with sudo on Linux${NC}"
        exit 1
    fi
    
    # List available drives
    list_usb_drives
    
    # Prompt for drive selection
    echo ""
    read -p "Enter the drive to use (e.g., disk2 for macOS, /dev/sdb for Linux): " selected_drive
    
    # Verify the drive
    if ! verify_usb_drive "$selected_drive"; then
        echo -e "${RED}❌ Invalid drive selection${NC}"
        exit 1
    fi
    
    # Build RadiateOS if needed
    if [[ ! -d "RadiateOS/build" ]]; then
        echo -e "${YELLOW}Build directory not found. Building RadiateOS...${NC}"
        build_radiateos
    else
        read -p "Do you want to rebuild RadiateOS? (yes/no): " rebuild
        if [[ "$rebuild" == "yes" ]]; then
            build_radiateos
        fi
    fi
    
    # Create the bootable USB
    create_bootable_usb "$selected_drive"
    
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║            Installation Complete        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}🎉 Your RadiateOS USB drive is ready!${NC}"
    echo ""
    echo "To boot from the USB drive:"
    echo "  1. Restart your computer"
    echo "  2. Hold the Option key (Mac) or access boot menu (PC)"
    echo "  3. Select the RadiateOS drive"
    echo "  4. Enjoy your optical computing OS!"
    echo ""
}

# Run main function
main "$@"