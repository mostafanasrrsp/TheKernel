#!/bin/bash
# RadiateOS Installation Script for HP Pavilion
# Automated installer for HP Pavilion with Intel Core i7 and NVIDIA GPU

set -e

VERSION="1.0.0"
INSTALL_DIR="/radiateos"
BOOT_PARTITION=""
ROOT_PARTITION=""
SWAP_PARTITION=""

echo "╔══════════════════════════════════════════════╗"
echo "║     RadiateOS Installer for HP Pavilion     ║"
echo "║         Intel Core i7 + NVIDIA GPU          ║"
echo "║              Version ${VERSION}              ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_section() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
    echo "────────────────────────────────────────"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root (sudo $0)"
    exit 1
fi

# Detect system
detect_system() {
    log_section "System Detection"
    
    # CPU Detection
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    if [[ $CPU_MODEL == *"i7"* ]]; then
        log_info "Intel Core i7 detected: $CPU_MODEL"
    else
        log_warning "Different CPU detected: $CPU_MODEL"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # GPU Detection
    if lspci | grep -i nvidia > /dev/null; then
        GPU_MODEL=$(lspci | grep -i nvidia | head -n1)
        log_info "NVIDIA GPU detected: $GPU_MODEL"
    else
        log_warning "No NVIDIA GPU detected"
        log_warning "NVIDIA-specific features will be disabled"
    fi
    
    # Touchscreen Detection
    if xinput list 2>/dev/null | grep -i touch > /dev/null; then
        log_info "Touchscreen detected"
    else
        log_warning "No touchscreen detected (may require driver installation)"
    fi
    
    # Memory Check
    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$TOTAL_MEM" -lt 4 ]; then
        log_error "Insufficient memory. Minimum 4GB required, found ${TOTAL_MEM}GB"
        exit 1
    else
        log_info "Memory: ${TOTAL_MEM}GB detected"
    fi
    
    # Disk Space Check
    AVAILABLE_SPACE=$(df / | awk 'NR==2 {print int($4/1048576)}')
    if [ "$AVAILABLE_SPACE" -lt 20 ]; then
        log_error "Insufficient disk space. Minimum 20GB required, found ${AVAILABLE_SPACE}GB"
        exit 1
    else
        log_info "Disk space: ${AVAILABLE_SPACE}GB available"
    fi
}

# Partition setup
setup_partitions() {
    log_section "Disk Partitioning"
    
    echo "Available disks:"
    lsblk -d -o NAME,SIZE,MODEL
    echo ""
    
    read -p "Enter target disk (e.g., sda, nvme0n1): " DISK
    
    if [ ! -b "/dev/$DISK" ]; then
        log_error "Disk /dev/$DISK not found"
        exit 1
    fi
    
    log_warning "This will ERASE ALL DATA on /dev/$DISK"
    read -p "Are you absolutely sure? Type 'yes' to continue: " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
        log_error "Installation cancelled"
        exit 1
    fi
    
    log_info "Partitioning /dev/$DISK..."
    
    # Clear existing partitions
    wipefs -a /dev/$DISK
    
    # Create GPT partition table
    parted /dev/$DISK mklabel gpt
    
    # Create partitions
    parted /dev/$DISK mkpart primary fat32 1MiB 512MiB  # EFI
    parted /dev/$DISK set 1 esp on
    parted /dev/$DISK mkpart primary linux-swap 512MiB 8704MiB  # Swap (8GB)
    parted /dev/$DISK mkpart primary ext4 8704MiB 100%  # Root
    
    # Format partitions
    if [[ $DISK == nvme* ]]; then
        BOOT_PARTITION="/dev/${DISK}p1"
        SWAP_PARTITION="/dev/${DISK}p2"
        ROOT_PARTITION="/dev/${DISK}p3"
    else
        BOOT_PARTITION="/dev/${DISK}1"
        SWAP_PARTITION="/dev/${DISK}2"
        ROOT_PARTITION="/dev/${DISK}3"
    fi
    
    log_info "Formatting partitions..."
    mkfs.fat -F32 $BOOT_PARTITION
    mkswap $SWAP_PARTITION
    mkfs.ext4 -F $ROOT_PARTITION
    
    # Mount partitions
    mount $ROOT_PARTITION /mnt
    mkdir -p /mnt/boot/efi
    mount $BOOT_PARTITION /mnt/boot/efi
    swapon $SWAP_PARTITION
    
    log_info "Partitions created and mounted"
}

# Install base system
install_base_system() {
    log_section "Installing Base System"
    
    log_info "Installing RadiateOS core..."
    
    # Copy system files
    cp -ax / /mnt/ 2>/dev/null || true
    
    # Install kernel
    log_info "Installing optimized kernel..."
    cp /boot/vmlinuz-*-radiateos /mnt/boot/
    cp /boot/initrd.img-*-radiateos /mnt/boot/
    
    # Install GRUB
    log_info "Installing bootloader..."
    grub-install --target=x86_64-efi --efi-directory=/mnt/boot/efi --bootloader-id=RadiateOS --root-directory=/mnt
    
    # Configure fstab
    log_info "Configuring filesystem..."
    cat > /mnt/etc/fstab << EOF
# RadiateOS filesystem table
UUID=$(blkid -s UUID -o value $ROOT_PARTITION) /               ext4    errors=remount-ro 0       1
UUID=$(blkid -s UUID -o value $BOOT_PARTITION) /boot/efi       vfat    umask=0077      0       1
UUID=$(blkid -s UUID -o value $SWAP_PARTITION) none            swap    sw              0       0
EOF
    
    # Configure hostname
    echo "radiateos-pavilion" > /mnt/etc/hostname
    
    # Configure network
    cat > /mnt/etc/hosts << EOF
127.0.0.1   localhost
127.0.1.1   radiateos-pavilion
EOF
}

# Install drivers
install_drivers() {
    log_section "Installing Hardware Drivers"
    
    # Install NVIDIA driver
    if lspci | grep -i nvidia > /dev/null; then
        log_info "Installing NVIDIA driver..."
        chroot /mnt /opt/scripts/install_nvidia_driver.sh
    fi
    
    # Configure touchscreen
    log_info "Configuring touchscreen support..."
    chroot /mnt /opt/scripts/configure_touchscreen.sh
    
    # Install Intel microcode
    log_info "Installing Intel microcode..."
    chroot /mnt apt-get install -y intel-microcode
    
    # Install HP-specific drivers
    log_info "Installing HP Pavilion drivers..."
    chroot /mnt apt-get install -y \
        hp-ppd \
        hplip \
        hp-health \
        laptop-mode-tools
}

# Configure system
configure_system() {
    log_section "System Configuration"
    
    # Set up display server
    log_info "Configuring display server..."
    chroot /mnt /opt/scripts/setup_display_server.sh
    
    # Create user
    log_info "Creating user account..."
    read -p "Enter username: " USERNAME
    chroot /mnt useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev $USERNAME
    echo "Set password for $USERNAME:"
    chroot /mnt passwd $USERNAME
    
    # Configure auto-login (optional)
    read -p "Enable auto-login? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sed -i "s/AutomaticLogin=.*/AutomaticLogin=$USERNAME/" /mnt/etc/gdm3/custom.conf
        sed -i "s/AutomaticLoginEnable=.*/AutomaticLoginEnable=true/" /mnt/etc/gdm3/custom.conf
    fi
    
    # Install RadiateOS UI
    log_info "Installing RadiateOS UI components..."
    cp -r /opt/radiateos-ui /mnt/opt/
    
    # Enable services
    log_info "Enabling system services..."
    chroot /mnt systemctl enable gdm3
    chroot /mnt systemctl enable NetworkManager
    chroot /mnt systemctl enable bluetooth
    chroot /mnt systemctl enable cups
    
    # Update GRUB
    log_info "Updating bootloader configuration..."
    chroot /mnt update-grub
}

# Post-installation
post_installation() {
    log_section "Finalizing Installation"
    
    # Generate initramfs
    log_info "Generating initramfs..."
    chroot /mnt update-initramfs -u -k all
    
    # Clean up
    log_info "Cleaning up..."
    chroot /mnt apt-get clean
    chroot /mnt apt-get autoremove -y
    
    # Create welcome file
    cat > /mnt/home/$USERNAME/Welcome.txt << EOF
Welcome to RadiateOS ${VERSION}!
================================

Your HP Pavilion is now running RadiateOS with:
- Intel Core i7 optimizations
- NVIDIA GPU support (if available)
- Touchscreen support
- Multi-touch gestures

Quick Commands:
- System Info: neofetch
- GPU Status: nvidia-smi
- Calibrate Touch: calibrate-touchscreen
- Test Touch: test-touchscreen

Enjoy your new RadiateOS system!
EOF
    
    chown 1000:1000 /mnt/home/$USERNAME/Welcome.txt
}

# Main installation flow
main() {
    echo ""
    echo "Starting RadiateOS installation..."
    echo ""
    
    # Run installation steps
    detect_system
    setup_partitions
    install_base_system
    install_drivers
    configure_system
    post_installation
    
    # Unmount
    log_info "Unmounting filesystems..."
    umount /mnt/boot/efi
    umount /mnt
    swapoff $SWAP_PARTITION
    
    # Complete
    echo ""
    echo "╔══════════════════════════════════════════════╗"
    echo "║        Installation Complete!                ║"
    echo "╚══════════════════════════════════════════════╝"
    echo ""
    echo "RadiateOS ${VERSION} has been successfully installed!"
    echo ""
    echo "Please remove the installation media and reboot."
    echo ""
    read -p "Reboot now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        reboot
    fi
}

# Run installation
main "$@"