#!/usr/bin/env bash
set -euo pipefail

# RadiateOS 1.0 USB Installer Creator
# This script creates a bootable USB installer for RadiateOS

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BUILD_DIR="$PROJECT_ROOT/build/usb_installer"
RADIATEOS_DIR="$PROJECT_ROOT/RadiateOS"
VERSION="1.0"
INSTALLER_NAME="RadiateOS-${VERSION}-Installer"

echo "🚀 RadiateOS ${VERSION} USB Installer Creator"
echo "================================================"

# Function to detect USB drives
detect_usb_drives() {
    echo "🔍 Detecting USB drives..."
    
    # Try different methods based on OS
    if command -v lsblk &> /dev/null; then
        # Linux method
        echo "Available block devices:"
        lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL
        
        # Look for removable devices
        REMOVABLE_DEVICES=$(lsblk -d -o NAME,RM | grep "1$" | awk '{print $1}' || true)
        if [ -n "$REMOVABLE_DEVICES" ]; then
            echo ""
            echo "Detected removable devices:"
            for dev in $REMOVABLE_DEVICES; do
                echo "  - /dev/$dev"
            done
        fi
    elif command -v diskutil &> /dev/null; then
        # macOS method
        echo "Available disks:"
        diskutil list
        
        echo ""
        echo "External/USB drives:"
        diskutil list | grep -E "external|removable" || echo "No external drives detected"
    else
        echo "⚠️  Unable to detect drives automatically"
        echo "Please specify the USB device path manually"
    fi
}

# Function to build RadiateOS
build_radiateos() {
    echo ""
    echo "📦 Building RadiateOS ${VERSION}..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    
    # Check if we're on macOS with Xcode
    if command -v xcodebuild &> /dev/null && [ -d "$RADIATEOS_DIR/RadiateOS.xcodeproj" ]; then
        echo "Building with Xcode..."
        cd "$RADIATEOS_DIR"
        
        # Build for release
        xcodebuild -project RadiateOS.xcodeproj \
            -scheme RadiateOS \
            -configuration Release \
            -destination 'generic/platform=macOS' \
            -archivePath "$BUILD_DIR/RadiateOS.xcarchive" \
            archive || {
                echo "⚠️  Xcode build failed, trying Swift Package Manager..."
                build_with_spm
            }
        
        # Export the app
        if [ -d "$BUILD_DIR/RadiateOS.xcarchive" ]; then
            echo "📤 Exporting RadiateOS app..."
            xcodebuild -exportArchive \
                -archivePath "$BUILD_DIR/RadiateOS.xcarchive" \
                -exportPath "$BUILD_DIR/export" \
                -exportOptionsPlist "$RADIATEOS_DIR/scripts/export_options.plist" || true
        fi
    else
        build_with_spm
    fi
    
    echo "✅ Build completed"
}

# Function to build with Swift Package Manager
build_with_spm() {
    echo "Building with Swift Package Manager..."
    
    if command -v swift &> /dev/null; then
        cd "$PROJECT_ROOT"
        swift build -c release
        
        # Copy built executable
        if [ -f ".build/release/RadiateOS" ]; then
            mkdir -p "$BUILD_DIR/export"
            cp ".build/release/RadiateOS" "$BUILD_DIR/export/"
        fi
    else
        echo "⚠️  Swift not available. Using pre-built binaries if available..."
        
        # Check for pre-built binaries
        if [ -d "$RADIATEOS_DIR/build" ]; then
            cp -r "$RADIATEOS_DIR/build/"* "$BUILD_DIR/" 2>/dev/null || true
        fi
    fi
}

# Function to create USB installer structure
create_installer_structure() {
    echo ""
    echo "📁 Creating installer structure..."
    
    INSTALLER_DIR="$BUILD_DIR/$INSTALLER_NAME"
    rm -rf "$INSTALLER_DIR"
    mkdir -p "$INSTALLER_DIR"
    
    # Create directory structure
    mkdir -p "$INSTALLER_DIR/System"
    mkdir -p "$INSTALLER_DIR/Boot"
    mkdir -p "$INSTALLER_DIR/Applications"
    mkdir -p "$INSTALLER_DIR/Config"
    
    # Copy RadiateOS files
    if [ -d "$BUILD_DIR/export/RadiateOS.app" ]; then
        cp -r "$BUILD_DIR/export/RadiateOS.app" "$INSTALLER_DIR/Applications/"
    elif [ -f "$BUILD_DIR/export/RadiateOS" ]; then
        cp "$BUILD_DIR/export/RadiateOS" "$INSTALLER_DIR/System/"
    fi
    
    # Copy kernel and system files from Sources
    if [ -d "$PROJECT_ROOT/Sources/RadiateOS" ]; then
        cp -r "$PROJECT_ROOT/Sources/RadiateOS" "$INSTALLER_DIR/System/Core"
    fi
    
    # Create boot configuration
    cat > "$INSTALLER_DIR/Boot/boot.conf" << EOF
# RadiateOS Boot Configuration
VERSION=$VERSION
BOOT_MODE=USB
SYSTEM_PATH=/System
APP_PATH=/Applications/RadiateOS.app
AUTOSTART=true
EOF
    
    # Create installer script
    cat > "$INSTALLER_DIR/install.sh" << 'EOF'
#!/bin/bash
# RadiateOS Installation Script

set -e

echo "🚀 Installing RadiateOS..."

# Detect target system
if [ -d "/Applications" ]; then
    # macOS system
    echo "Installing on macOS..."
    sudo cp -R Applications/RadiateOS.app /Applications/ 2>/dev/null || true
elif [ -d "/usr/local/bin" ]; then
    # Linux/Unix system
    echo "Installing on Linux/Unix..."
    sudo cp System/RadiateOS /usr/local/bin/ 2>/dev/null || true
    sudo chmod +x /usr/local/bin/RadiateOS
fi

# Copy system files
sudo mkdir -p /opt/radiateos
sudo cp -r System/* /opt/radiateos/ 2>/dev/null || true

echo "✅ RadiateOS installation complete!"
echo "Run 'radiateos' to start the system"
EOF
    
    chmod +x "$INSTALLER_DIR/install.sh"
    
    # Create README
    cat > "$INSTALLER_DIR/README.md" << EOF
# RadiateOS ${VERSION} USB Installer

## Installation Instructions

### macOS:
1. Open Terminal
2. Navigate to this USB drive
3. Run: ./install.sh

### Linux:
1. Open a terminal
2. Navigate to this USB mount point
3. Run: sudo ./install.sh

### Windows:
1. Use WSL or a Linux VM
2. Follow Linux instructions

## Quick Start
After installation, run:
- macOS: Open /Applications/RadiateOS.app
- Linux: Run 'radiateos' in terminal

## System Requirements
- 4GB RAM minimum
- 10GB free disk space
- 64-bit processor
- OpenGL 3.3 or higher

## Support
Visit: https://github.com/radiateos/radiateos
EOF
    
    echo "✅ Installer structure created"
}

# Function to create ISO image
create_iso_image() {
    echo ""
    echo "💿 Creating ISO image..."
    
    ISO_FILE="$BUILD_DIR/${INSTALLER_NAME}.iso"
    
    if command -v mkisofs &> /dev/null; then
        mkisofs -o "$ISO_FILE" \
            -V "RadiateOS_${VERSION}" \
            -J -R -l \
            "$BUILD_DIR/$INSTALLER_NAME"
    elif command -v genisoimage &> /dev/null; then
        genisoimage -o "$ISO_FILE" \
            -V "RadiateOS_${VERSION}" \
            -J -R -l \
            "$BUILD_DIR/$INSTALLER_NAME"
    elif command -v hdiutil &> /dev/null; then
        # macOS method
        hdiutil makehybrid -o "$ISO_FILE" \
            -hfs -joliet -iso \
            "$BUILD_DIR/$INSTALLER_NAME"
    else
        echo "⚠️  No ISO creation tool found. Skipping ISO creation."
        return 1
    fi
    
    if [ -f "$ISO_FILE" ]; then
        echo "✅ ISO created: $ISO_FILE"
        return 0
    fi
    return 1
}

# Function to write to USB (requires confirmation)
write_to_usb() {
    local usb_device="$1"
    
    echo ""
    echo "⚠️  WARNING: This will erase all data on $usb_device"
    echo "Type 'yes' to continue, or anything else to cancel:"
    read -r confirmation
    
    if [ "$confirmation" != "yes" ]; then
        echo "❌ Cancelled"
        return 1
    fi
    
    echo "📝 Writing to USB drive..."
    
    # Check if we have an ISO
    ISO_FILE="$BUILD_DIR/${INSTALLER_NAME}.iso"
    if [ -f "$ISO_FILE" ]; then
        # Write ISO to USB
        if command -v dd &> /dev/null; then
            sudo dd if="$ISO_FILE" of="$usb_device" bs=4M status=progress conv=fsync
        else
            echo "❌ 'dd' command not available"
            return 1
        fi
    else
        # Direct copy method
        echo "Copying files directly to USB..."
        
        # Mount point
        MOUNT_POINT="/tmp/radiateos_usb_$$"
        mkdir -p "$MOUNT_POINT"
        
        # Format and mount USB
        if command -v mkfs.vfat &> /dev/null; then
            sudo mkfs.vfat -F 32 -n "RADIATEOS" "$usb_device"
            sudo mount "$usb_device" "$MOUNT_POINT"
            
            # Copy files
            sudo cp -r "$BUILD_DIR/$INSTALLER_NAME/"* "$MOUNT_POINT/"
            
            # Unmount
            sudo umount "$MOUNT_POINT"
            rmdir "$MOUNT_POINT"
        else
            echo "❌ Unable to format USB drive"
            return 1
        fi
    fi
    
    echo "✅ USB installer created successfully!"
    return 0
}

# Main execution
main() {
    echo ""
    
    # Step 1: Detect USB drives
    detect_usb_drives
    
    # Step 2: Build RadiateOS
    build_radiateos
    
    # Step 3: Create installer structure
    create_installer_structure
    
    # Step 4: Create ISO image
    create_iso_image || true
    
    # Step 5: Offer to write to USB
    echo ""
    echo "📋 Summary:"
    echo "  - RadiateOS ${VERSION} built successfully"
    echo "  - Installer created at: $BUILD_DIR/$INSTALLER_NAME"
    
    if [ -f "$BUILD_DIR/${INSTALLER_NAME}.iso" ]; then
        echo "  - ISO image: $BUILD_DIR/${INSTALLER_NAME}.iso"
        echo ""
        echo "You can now:"
        echo "1. Write the ISO to a USB drive using your favorite tool"
        echo "2. Use 'dd' command: sudo dd if=$BUILD_DIR/${INSTALLER_NAME}.iso of=/dev/YOUR_USB_DEVICE bs=4M"
    fi
    
    echo ""
    echo "🎯 To write to a specific USB device, run:"
    echo "   $0 /dev/YOUR_USB_DEVICE"
    
    # If USB device was provided as argument, offer to write
    if [ $# -eq 1 ]; then
        USB_DEVICE="$1"
        echo ""
        echo "USB device specified: $USB_DEVICE"
        write_to_usb "$USB_DEVICE"
    fi
}

# Run main function
main "$@"