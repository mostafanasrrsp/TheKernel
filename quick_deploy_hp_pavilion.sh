#!/bin/bash
# RadiateOS Quick Deploy for HP Pavilion
# Fast deployment script for immediate installation

set -e

echo "============================================"
echo "   RadiateOS Quick Deploy - HP Pavilion"
echo "============================================"
echo "This script will:"
echo "1. Download required components"
echo "2. Build RadiateOS for PC"
echo "3. Create bootable installer"
echo "4. Provide installation instructions"
echo "============================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run with sudo: sudo $0"
    exit 1
fi

# Quick dependency installation
log_info "Installing dependencies..."
apt-get update
apt-get install -y docker.io git wget curl build-essential

# Start Docker
systemctl start docker
systemctl enable docker

# Make scripts executable
log_info "Preparing build scripts..."
chmod +x pc-build/scripts/*.sh
chmod +x build_radiateos_pc.sh

# Run the main build
log_info "Starting RadiateOS build..."
./build_radiateos_pc.sh

# Check if ISO was created
if [ -f "output/RadiateOS-1.0.0-amd64.iso" ]; then
    log_info "Build successful!"
    
    echo ""
    echo "============================================"
    echo "   INSTALLATION INSTRUCTIONS"
    echo "============================================"
    echo ""
    echo "OPTION 1: Create Bootable USB (Recommended)"
    echo "--------------------------------------------"
    echo "1. Insert USB drive (8GB minimum)"
    echo "2. Find your USB device:"
    echo "   $ lsblk"
    echo ""
    echo "3. Write ISO to USB (replace sdX with your device):"
    echo "   $ sudo dd if=output/RadiateOS-1.0.0-amd64.iso of=/dev/sdX bs=4M status=progress"
    echo ""
    echo "4. Boot HP Pavilion from USB:"
    echo "   - Restart computer"
    echo "   - Press F9 or ESC during boot"
    echo "   - Select USB drive from boot menu"
    echo ""
    echo "OPTION 2: Direct Installation (Advanced)"
    echo "--------------------------------------------"
    echo "1. Mount ISO:"
    echo "   $ sudo mkdir /mnt/radiateos"
    echo "   $ sudo mount -o loop output/RadiateOS-1.0.0-amd64.iso /mnt/radiateos"
    echo ""
    echo "2. Run installer:"
    echo "   $ sudo /mnt/radiateos/install.sh"
    echo ""
    echo "OPTION 3: Virtual Machine Testing"
    echo "--------------------------------------------"
    echo "1. Install VirtualBox or VMware"
    echo "2. Create new VM with:"
    echo "   - Type: Linux"
    echo "   - Version: Ubuntu 64-bit"
    echo "   - RAM: 4GB minimum"
    echo "   - Storage: 20GB minimum"
    echo "3. Mount ISO and boot"
    echo ""
    echo "============================================"
    echo "   HP PAVILION SPECIFIC SETTINGS"
    echo "============================================"
    echo ""
    echo "BIOS/UEFI Settings (Press F10 during boot):"
    echo "- Secure Boot: Disabled (for initial install)"
    echo "- Legacy Support: Enabled"
    echo "- Boot Order: USB First"
    echo ""
    echo "After Installation:"
    echo "- Touchscreen: Auto-detected"
    echo "- NVIDIA GPU: Run 'nvidia-smi' to verify"
    echo "- Calibrate touch: 'calibrate-touchscreen'"
    echo ""
    echo "============================================"
    
    # Offer to create USB immediately if device is connected
    echo ""
    read -p "Do you want to create a bootable USB now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Available USB devices:"
        lsblk -d -o NAME,SIZE,MODEL | grep -E "sd[b-z]|nvme"
        echo ""
        read -p "Enter device name (e.g., sdb, sdc): " DEVICE
        
        if [ -b "/dev/$DEVICE" ]; then
            log_warning "This will erase all data on /dev/$DEVICE"
            read -p "Are you sure? (yes/no): " CONFIRM
            
            if [ "$CONFIRM" = "yes" ]; then
                log_info "Writing ISO to /dev/$DEVICE..."
                dd if=output/RadiateOS-1.0.0-amd64.iso of=/dev/$DEVICE bs=4M status=progress conv=fsync
                sync
                log_info "Bootable USB created successfully!"
                echo ""
                echo "You can now boot your HP Pavilion from this USB drive!"
            fi
        else
            log_error "Device /dev/$DEVICE not found"
        fi
    fi
    
else
    log_error "Build failed! Check the logs above for errors."
    exit 1
fi

echo ""
echo "============================================"
echo "Support & Troubleshooting:"
echo "- Touchscreen not working: Run 'sudo configure_touchscreen.sh'"
echo "- GPU issues: Run 'sudo install_nvidia_driver.sh'"
echo "- Boot problems: Try Legacy BIOS mode in UEFI settings"
echo "============================================="