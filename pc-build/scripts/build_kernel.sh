#!/bin/bash
# RadiateOS Kernel Build Script for PC

set -e

KERNEL_VERSION="6.5.0"
JOBS=$(nproc)

echo "==================================="
echo "RadiateOS Kernel Builder"
echo "Target: HP Pavilion Intel Core i7"
echo "==================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root"
    exit 1
fi

# Navigate to kernel source
cd /usr/src/linux-${KERNEL_VERSION}

# Apply RadiateOS kernel configuration
log_info "Applying RadiateOS kernel configuration..."
if [ -f /opt/kernel_config ]; then
    cp /opt/kernel_config .config
else
    log_warning "Using default configuration"
    make defconfig
fi

# Configure for HP Pavilion hardware
log_info "Configuring for HP Pavilion hardware..."
scripts/config --enable CONFIG_CPU_SUP_INTEL
scripts/config --enable CONFIG_DRM_NOUVEAU
scripts/config --enable CONFIG_TOUCHSCREEN_USB_COMPOSITE
scripts/config --enable CONFIG_HID_MULTITOUCH
scripts/config --enable CONFIG_HP_WMI
scripts/config --enable CONFIG_EFI
scripts/config --enable CONFIG_EFI_STUB

# Update configuration
make olddefconfig

# Build kernel
log_info "Building kernel with ${JOBS} parallel jobs..."
make -j${JOBS} bzImage

# Build modules
log_info "Building kernel modules..."
make -j${JOBS} modules

# Install modules
log_info "Installing kernel modules..."
make modules_install

# Copy kernel image
log_info "Installing kernel image..."
cp arch/x86/boot/bzImage /boot/vmlinuz-${KERNEL_VERSION}-radiateos
cp System.map /boot/System.map-${KERNEL_VERSION}-radiateos
cp .config /boot/config-${KERNEL_VERSION}-radiateos

# Generate initramfs
log_info "Generating initramfs..."
mkinitramfs -o /boot/initrd.img-${KERNEL_VERSION}-radiateos ${KERNEL_VERSION}

# Update GRUB
log_info "Updating bootloader..."
update-grub

log_info "Kernel build complete!"
log_info "Kernel installed at: /boot/vmlinuz-${KERNEL_VERSION}-radiateos"
log_info "Initramfs at: /boot/initrd.img-${KERNEL_VERSION}-radiateos"

echo "==================================="
echo "Build Summary:"
echo "- Kernel: ${KERNEL_VERSION}-radiateos"
echo "- Architecture: x86_64"
echo "- CPU: Intel Core i7 optimized"
echo "- GPU: NVIDIA support enabled"
echo "- Touchscreen: Enabled"
echo "==================================="