#!/usr/bin/env bash
set -euo pipefail

# RadiateOS USB Status Checker
# Checks the status of USB drives and RadiateOS installation

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║      RadiateOS USB Status Checker      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
else
    echo -e "${RED}❌ Unsupported platform: $OSTYPE${NC}"
    exit 1
fi

echo -e "${GREEN}Platform: $PLATFORM${NC}"
echo ""

# Function to check USB drives on macOS
check_macos_usb() {
    echo -e "${BLUE}📱 External Drives:${NC}"
    echo "─────────────────────────────────────────"
    
    # List all external drives
    diskutil list external | while IFS= read -r line; do
        if echo "$line" | grep -q "disk[0-9]"; then
            disk=$(echo "$line" | awk '{print $1}')
            
            # Get detailed info
            info=$(diskutil info "$disk" 2>/dev/null)
            if [[ $? -eq 0 ]]; then
                name=$(echo "$info" | grep "Media Name:" | cut -d: -f2 | xargs)
                size=$(echo "$info" | grep "Disk Size:" | awk '{print $3, $4}')
                protocol=$(echo "$info" | grep "Protocol:" | cut -d: -f2 | xargs)
                removable=$(echo "$info" | grep "Removable Media:" | cut -d: -f2 | xargs)
                
                echo -e "${GREEN}Drive: $disk${NC}"
                echo "  Name: ${name:-Unknown}"
                echo "  Size: ${size:-Unknown}"
                echo "  Protocol: ${protocol:-Unknown}"
                echo "  Removable: ${removable:-Unknown}"
                
                # Check for RadiateOS
                volumes=$(diskutil list "$disk" | grep -E "^\s+[0-9]:" | awk '{print $NF}')
                for vol in $volumes; do
                    if [[ -d "/Volumes/$vol" ]]; then
                        echo "  Volume: /Volumes/$vol"
                        
                        # Check for RadiateOS installation
                        if [[ -d "/Volumes/$vol/Applications/RadiateOS.app" ]]; then
                            echo -e "  ${GREEN}✅ RadiateOS found!${NC}"
                            
                            # Check app info
                            if [[ -f "/Volumes/$vol/Applications/RadiateOS.app/Contents/Info.plist" ]]; then
                                version=$(defaults read "/Volumes/$vol/Applications/RadiateOS.app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "Unknown")
                                echo "    Version: $version"
                            fi
                        fi
                        
                        # Check for boot files
                        if [[ -f "/Volumes/$vol/EFI/BOOT/startup.nsh" ]]; then
                            echo -e "  ${GREEN}✅ Boot loader found${NC}"
                        fi
                    fi
                done
                echo "─────────────────────────────────────────"
            fi
        fi
    done
    
    # Check if no external drives found
    if ! diskutil list external | grep -q "disk[0-9]"; then
        echo -e "${YELLOW}No external drives detected${NC}"
    fi
}

# Function to check USB drives on Linux
check_linux_usb() {
    echo -e "${BLUE}📱 USB Drives:${NC}"
    echo "─────────────────────────────────────────"
    
    # List USB drives
    for device in /sys/block/sd*; do
        if [[ -e "$device" ]]; then
            dev_name=$(basename "$device")
            
            # Check if it's a USB device
            if readlink "$device" | grep -q usb; then
                echo -e "${GREEN}Drive: /dev/$dev_name${NC}"
                
                # Get device info
                if [[ -f "$device/device/vendor" ]]; then
                    vendor=$(cat "$device/device/vendor" | xargs)
                    echo "  Vendor: $vendor"
                fi
                
                if [[ -f "$device/device/model" ]]; then
                    model=$(cat "$device/device/model" | xargs)
                    echo "  Model: $model"
                fi
                
                if [[ -f "$device/size" ]]; then
                    size_blocks=$(cat "$device/size")
                    size_gb=$((size_blocks * 512 / 1073741824))
                    echo "  Size: ${size_gb} GB"
                fi
                
                # Check partitions
                for part in "$device"/"$dev_name"*; do
                    if [[ -d "$part" ]] && [[ "$part" != "$device/$dev_name" ]]; then
                        part_name=$(basename "$part")
                        echo "  Partition: /dev/$part_name"
                        
                        # Check if mounted
                        mount_point=$(findmnt -n -o TARGET "/dev/$part_name" 2>/dev/null)
                        if [[ -n "$mount_point" ]]; then
                            echo "    Mounted at: $mount_point"
                            
                            # Check for RadiateOS
                            if [[ -f "$mount_point/bin/RadiateOS" ]]; then
                                echo -e "    ${GREEN}✅ RadiateOS binary found!${NC}"
                            fi
                            
                            if [[ -f "$mount_point/boot/grub.cfg" ]]; then
                                echo -e "    ${GREEN}✅ Boot configuration found${NC}"
                            fi
                        else
                            echo "    Not mounted"
                        fi
                    fi
                done
                echo "─────────────────────────────────────────"
            fi
        fi
    done
    
    # Check if no USB drives found
    usb_count=$(ls /sys/block/sd* 2>/dev/null | xargs -I {} readlink {} | grep -c usb || echo "0")
    if [[ "$usb_count" == "0" ]]; then
        echo -e "${YELLOW}No USB drives detected${NC}"
        echo ""
        echo "Tip: Make sure your USB drive is connected"
        echo "     You may need to run this script with sudo"
    fi
}

# Function to check project status
check_project_status() {
    echo ""
    echo -e "${BLUE}📦 Project Status:${NC}"
    echo "─────────────────────────────────────────"
    
    # Check if RadiateOS directory exists
    if [[ -d "RadiateOS" ]]; then
        echo -e "${GREEN}✅ RadiateOS directory found${NC}"
        
        # Check for build artifacts
        if [[ -d "RadiateOS/build" ]]; then
            echo -e "${GREEN}✅ Build directory exists${NC}"
            
            # Check for app
            if [[ "$PLATFORM" == "macos" ]]; then
                if [[ -d "RadiateOS/build/export/RadiateOS.app" ]] || \
                   [[ -d "RadiateOS/build/macos/RadiateOS.xcarchive/Products/Applications/RadiateOS.app" ]]; then
                    echo -e "${GREEN}✅ RadiateOS.app built${NC}"
                else
                    echo -e "${YELLOW}⚠️  RadiateOS.app not found - need to build${NC}"
                fi
            else
                if [[ -f ".build/release/RadiateOS" ]]; then
                    echo -e "${GREEN}✅ RadiateOS binary built${NC}"
                else
                    echo -e "${YELLOW}⚠️  RadiateOS binary not found - need to build${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}⚠️  Build directory not found - need to build${NC}"
        fi
    else
        echo -e "${RED}❌ RadiateOS directory not found${NC}"
    fi
    
    # Check for installer script
    if [[ -f "create_usb_installer.sh" ]]; then
        echo -e "${GREEN}✅ USB installer script ready${NC}"
    else
        echo -e "${YELLOW}⚠️  USB installer script not found${NC}"
    fi
}

# Function to provide recommendations
provide_recommendations() {
    echo ""
    echo -e "${CYAN}📋 Recommendations:${NC}"
    echo "─────────────────────────────────────────"
    
    # Check if any USB drives are connected
    if [[ "$PLATFORM" == "macos" ]]; then
        if ! diskutil list external | grep -q "disk[0-9]"; then
            echo "1. Connect a USB drive (8GB or larger recommended)"
        fi
    else
        usb_count=$(ls /sys/block/sd* 2>/dev/null | xargs -I {} readlink {} | grep -c usb || echo "0")
        if [[ "$usb_count" == "0" ]]; then
            echo "1. Connect a USB drive (8GB or larger recommended)"
        fi
    fi
    
    # Check if build is needed
    if [[ ! -d "RadiateOS/build" ]]; then
        echo "2. Build RadiateOS by running:"
        echo "   cd RadiateOS && ./scripts/build_macos_dmg.sh"
    fi
    
    # Check if installer script exists
    if [[ -f "create_usb_installer.sh" ]]; then
        echo "3. Run the USB installer:"
        echo "   ./create_usb_installer.sh"
    fi
    
    echo ""
    echo -e "${BLUE}Ready to create your RadiateOS USB drive!${NC}"
}

# Main execution
main() {
    # Check USB drives based on platform
    if [[ "$PLATFORM" == "macos" ]]; then
        check_macos_usb
    else
        check_linux_usb
    fi
    
    # Check project status
    check_project_status
    
    # Provide recommendations
    provide_recommendations
}

# Run main
main "$@"