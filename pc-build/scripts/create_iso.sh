#!/bin/bash
# RadiateOS ISO Creator for PC Installation

set -e

VERSION="1.0.0"
ARCH="amd64"
DISTRO_NAME="RadiateOS"
ISO_NAME="${DISTRO_NAME}-${VERSION}-${ARCH}.iso"
BUILD_DIR="/tmp/radiateos-build"
ISO_DIR="${BUILD_DIR}/iso"
FILESYSTEM_DIR="${BUILD_DIR}/filesystem"

echo "========================================="
echo "RadiateOS ISO Builder"
echo "Version: ${VERSION}"
echo "Architecture: ${ARCH}"
echo "========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "${BLUE}===> $1${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root"
    exit 1
fi

# Clean previous builds
log_section "Cleaning previous builds"
rm -rf ${BUILD_DIR}
mkdir -p ${ISO_DIR}/{boot,isolinux,install,casper,.disk}
mkdir -p ${FILESYSTEM_DIR}

# Install base system
log_section "Installing base system"
debootstrap --arch=${ARCH} jammy ${FILESYSTEM_DIR} http://archive.ubuntu.com/ubuntu/

# Mount necessary filesystems
log_info "Mounting filesystems..."
mount --bind /dev ${FILESYSTEM_DIR}/dev
mount --bind /dev/pts ${FILESYSTEM_DIR}/dev/pts
mount --bind /proc ${FILESYSTEM_DIR}/proc
mount --bind /sys ${FILESYSTEM_DIR}/sys

# Copy RadiateOS files
log_section "Installing RadiateOS components"
cp -r /opt/radiateos ${FILESYSTEM_DIR}/opt/
cp -r /opt/radiateos-sources ${FILESYSTEM_DIR}/opt/
cp -r /opt/scripts ${FILESYSTEM_DIR}/opt/

# Create chroot script
cat > ${FILESYSTEM_DIR}/tmp/setup.sh << 'CHROOT_SCRIPT'
#!/bin/bash
set -e

# Set hostname
echo "radiateos" > /etc/hostname

# Configure apt sources
cat > /etc/apt/sources.list << EOF
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse
EOF

# Update system
apt-get update
apt-get upgrade -y

# Install essential packages
apt-get install -y \
    linux-generic \
    linux-headers-generic \
    grub-pc \
    grub-efi-amd64 \
    network-manager \
    wireless-tools \
    wpasupplicant \
    build-essential \
    git \
    curl \
    wget \
    vim \
    nano \
    htop \
    neofetch \
    firefox \
    gnome-shell \
    gdm3 \
    gnome-terminal \
    nautilus \
    gnome-control-center \
    gnome-tweaks \
    plymouth \
    plymouth-themes \
    casper \
    lupin-casper \
    discover \
    laptop-detect \
    os-prober \
    zip \
    unzip \
    p7zip-full \
    p7zip-rar \
    rar \
    unrar \
    mesa-utils \
    vulkan-tools \
    vainfo \
    vdpauinfo \
    intel-media-va-driver \
    i965-va-driver \
    firmware-linux \
    firmware-linux-nonfree \
    bluez \
    bluez-tools \
    pulseaudio \
    pavucontrol \
    alsa-utils \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    ubuntu-restricted-extras \
    input-utils \
    xinput \
    xserver-xorg-input-all \
    xserver-xorg-video-all

# Install development tools
apt-get install -y \
    gcc \
    g++ \
    make \
    cmake \
    python3 \
    python3-pip \
    nodejs \
    npm \
    golang \
    rustc \
    cargo

# Install Swift
wget -q -O - https://download.swift.org/swift-5.9.2-release/ubuntu2204/swift-5.9.2-RELEASE/swift-5.9.2-RELEASE-ubuntu22.04.tar.gz | tar -xz -C / --strip-components=1

# Configure touchscreen support
cat > /etc/X11/xorg.conf.d/99-touchscreen.conf << EOF
Section "InputClass"
    Identifier "calibration"
    MatchProduct "Touchscreen"
    Option "Calibration" "0 65535 0 65535"
    Option "SwapAxes" "0"
EndSection
EOF

# Create RadiateOS user
useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev,bluetooth radiateos
echo "radiateos:radiateos" | chpasswd
echo "radiateos ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Configure auto-login
cat > /etc/gdm3/custom.conf << EOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=radiateos

[security]

[xdmcp]

[chooser]

[debug]
EOF

# Create desktop entry for RadiateOS
cat > /usr/share/applications/radiateos.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=RadiateOS System
Comment=RadiateOS System Manager
Exec=/opt/radiateos/radiateos
Icon=/opt/radiateos/icon.png
Terminal=false
Categories=System;Settings;
StartupNotify=true
EOF

# Configure Plymouth boot splash
update-alternatives --set default.plymouth /usr/share/plymouth/themes/bgrt/bgrt.plymouth
update-initramfs -u

# Clean apt cache
apt-get clean
rm -rf /var/lib/apt/lists/*

# Create version file
echo "${VERSION}" > /etc/radiateos-version

exit 0
CHROOT_SCRIPT

# Execute chroot script
log_info "Configuring system in chroot..."
chmod +x ${FILESYSTEM_DIR}/tmp/setup.sh
chroot ${FILESYSTEM_DIR} /tmp/setup.sh

# Unmount filesystems
log_info "Unmounting filesystems..."
umount ${FILESYSTEM_DIR}/sys
umount ${FILESYSTEM_DIR}/proc
umount ${FILESYSTEM_DIR}/dev/pts
umount ${FILESYSTEM_DIR}/dev

# Create manifest
log_section "Creating manifest"
chroot ${FILESYSTEM_DIR} dpkg-query -W --showformat='${Package} ${Version}\n' > ${ISO_DIR}/casper/filesystem.manifest
cp ${ISO_DIR}/casper/filesystem.manifest ${ISO_DIR}/casper/filesystem.manifest-desktop

# Compress filesystem
log_section "Compressing filesystem"
mksquashfs ${FILESYSTEM_DIR} ${ISO_DIR}/casper/filesystem.squashfs -comp xz -b 1M
printf $(du -sx --block-size=1 ${FILESYSTEM_DIR} | cut -f1) > ${ISO_DIR}/casper/filesystem.size

# Copy kernel and initrd
log_info "Copying kernel and initrd..."
cp ${FILESYSTEM_DIR}/boot/vmlinuz-* ${ISO_DIR}/casper/vmlinuz
cp ${FILESYSTEM_DIR}/boot/initrd.img-* ${ISO_DIR}/casper/initrd

# Create disk info
cat > ${ISO_DIR}/.disk/info << EOF
${DISTRO_NAME} ${VERSION} "${ARCH}" - $(date +%Y%m%d)
EOF

cat > ${ISO_DIR}/.disk/cd_type << EOF
full_cd/single
EOF

touch ${ISO_DIR}/.disk/base_installable

echo "full_cd/single" > ${ISO_DIR}/.disk/cd_type
echo "${DISTRO_NAME} ${VERSION}" > ${ISO_DIR}/.disk/info
echo "http://radiateos.com" > ${ISO_DIR}/.disk/release_notes_url

# Create ISOLINUX configuration
log_section "Configuring bootloader"
cp /usr/lib/ISOLINUX/isolinux.bin ${ISO_DIR}/isolinux/
cp /usr/lib/syslinux/modules/bios/*.c32 ${ISO_DIR}/isolinux/

cat > ${ISO_DIR}/isolinux/isolinux.cfg << EOF
DEFAULT live
LABEL live
  menu label ^Boot RadiateOS
  kernel /casper/vmlinuz
  append initrd=/casper/initrd boot=casper quiet splash ---
LABEL live-install
  menu label ^Install RadiateOS
  kernel /casper/vmlinuz
  append initrd=/casper/initrd boot=casper only-ubiquity quiet splash ---
LABEL check
  menu label ^Check disc for defects
  kernel /casper/vmlinuz
  append initrd=/casper/initrd boot=casper integrity-check quiet splash ---
LABEL memtest
  menu label Test ^memory
  kernel /install/mt86plus
LABEL hd
  menu label ^Boot from first hard disk
  localboot 0x80
EOF

# Create GRUB configuration for UEFI
mkdir -p ${ISO_DIR}/boot/grub
cat > ${ISO_DIR}/boot/grub/grub.cfg << EOF
set default=0
set timeout=10

menuentry "Boot RadiateOS" {
    linux /casper/vmlinuz boot=casper quiet splash
    initrd /casper/initrd
}

menuentry "Install RadiateOS" {
    linux /casper/vmlinuz boot=casper only-ubiquity quiet splash
    initrd /casper/initrd
}

menuentry "Check disc for defects" {
    linux /casper/vmlinuz boot=casper integrity-check quiet splash
    initrd /casper/initrd
}

menuentry "Test memory" {
    linux16 /install/mt86plus
}

menuentry "Boot from first hard disk" {
    set root=(hd0)
    chainloader +1
}
EOF

# Create EFI boot
log_info "Creating EFI boot..."
grub-mkstandalone \
    --format=x86_64-efi \
    --output=${ISO_DIR}/boot/grub/bootx64.efi \
    --locales="" \
    --fonts="" \
    "boot/grub/grub.cfg=${ISO_DIR}/boot/grub/grub.cfg"

# Create EFI partition
dd if=/dev/zero of=${ISO_DIR}/boot/grub/efi.img bs=1M count=10
mkfs.vfat ${ISO_DIR}/boot/grub/efi.img
mmd -i ${ISO_DIR}/boot/grub/efi.img efi efi/boot
mcopy -i ${ISO_DIR}/boot/grub/efi.img ${ISO_DIR}/boot/grub/bootx64.efi ::efi/boot/

# Create ISO
log_section "Creating ISO image"
xorriso \
    -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "${DISTRO_NAME}" \
    -eltorito-boot isolinux/isolinux.bin \
    -eltorito-catalog isolinux/boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -append_partition 2 0xef ${ISO_DIR}/boot/grub/efi.img \
    -output "/output/${ISO_NAME}" \
    -graft-points \
    "${ISO_DIR}" \
    /isolinux/isolinux.bin=${ISO_DIR}/isolinux/isolinux.bin \
    /boot/grub/bios.img=${ISO_DIR}/boot/grub/bios.img \
    /boot/grub/efi.img=${ISO_DIR}/boot/grub/efi.img

# Calculate checksums
log_info "Calculating checksums..."
cd /output
sha256sum ${ISO_NAME} > ${ISO_NAME}.sha256
md5sum ${ISO_NAME} > ${ISO_NAME}.md5

# Clean up
log_info "Cleaning up..."
rm -rf ${BUILD_DIR}

echo "========================================="
echo -e "${GREEN}ISO creation complete!${NC}"
echo "ISO: /output/${ISO_NAME}"
echo "SHA256: /output/${ISO_NAME}.sha256"
echo "Size: $(du -h /output/${ISO_NAME} | cut -f1)"
echo "========================================="
echo ""
echo "To create a bootable USB:"
echo "  dd if=/output/${ISO_NAME} of=/dev/sdX bs=4M status=progress"
echo ""
echo "Or use Rufus/Etcher for Windows"
echo "========================================="