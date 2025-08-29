#!/bin/bash
# RadiateOS PC Build Orchestrator
# Target: HP Pavilion with Intel Core i7 and NVIDIA GPU

set -e

VERSION="1.0.0"
BUILD_DATE=$(date +%Y%m%d)
OUTPUT_DIR="./output"

echo "============================================"
echo "     RadiateOS PC Build System"
echo "============================================"
echo "Version: ${VERSION}"
echo "Build Date: ${BUILD_DATE}"
echo "Target: HP Pavilion (Intel Core i7 + NVIDIA)"
echo "============================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
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

log_section() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_section "Checking Prerequisites"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed!"
        log_info "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
    else
        log_info "Docker: $(docker --version)"
    fi
    
    # Check required tools
    REQUIRED_TOOLS="git wget curl"
    for tool in $REQUIRED_TOOLS; do
        if ! command -v $tool &> /dev/null; then
            log_warning "$tool is not installed. Installing..."
            apt-get update && apt-get install -y $tool
        fi
    done
    
    log_info "All prerequisites satisfied"
}

# Build Docker image
build_docker_image() {
    log_section "Building Docker Image"
    
    cd pc-build
    docker build -t radiateos-builder:${VERSION} .
    cd ..
    
    log_info "Docker image built successfully"
}

# Build kernel
build_kernel() {
    log_section "Building Linux Kernel"
    
    docker run --rm \
        -v $(pwd)/pc-build:/opt \
        -v $(pwd)/output:/output \
        --privileged \
        radiateos-builder:${VERSION} \
        /opt/scripts/build_kernel.sh
    
    log_info "Kernel build complete"
}

# Build RadiateOS components
build_radiateos() {
    log_section "Building RadiateOS Components"
    
    # Convert Swift code to Linux-compatible binaries
    docker run --rm \
        -v $(pwd)/Sources:/sources \
        -v $(pwd)/RadiateOS:/radiateos \
        -v $(pwd)/output:/output \
        radiateos-builder:${VERSION} \
        bash -c "
            cd /sources
            swift build -c release
            cp .build/release/RadiateOS /output/
        "
    
    log_info "RadiateOS components built"
}

# Create ISO
create_iso() {
    log_section "Creating Bootable ISO"
    
    docker run --rm \
        -v $(pwd):/workspace \
        -v $(pwd)/output:/output \
        --privileged \
        radiateos-builder:${VERSION} \
        /workspace/pc-build/scripts/create_iso.sh
    
    log_info "ISO created successfully"
}

# Create USB installer
create_usb_installer() {
    log_section "USB Installer Instructions"
    
    cat << EOF
========================================
To create a bootable USB drive:
========================================

1. Insert a USB drive (8GB or larger)
2. Find your USB device:
   $ lsblk
   
3. Create bootable USB (replace sdX with your device):
   $ sudo dd if=${OUTPUT_DIR}/RadiateOS-${VERSION}-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync
   
4. For Windows users:
   - Use Rufus: https://rufus.ie
   - Or Etcher: https://www.balena.io/etcher/
   
========================================
EOF
}

# Main build process
main() {
    log_section "Starting RadiateOS PC Build"
    
    # Create output directory
    mkdir -p ${OUTPUT_DIR}
    
    # Check prerequisites
    check_prerequisites
    
    # Build steps
    build_docker_image
    build_kernel
    build_radiateos
    create_iso
    
    # Generate installation instructions
    create_usb_installer
    
    # Generate system report
    log_section "Build Complete!"
    
    cat << EOF
========================================
Build Summary:
========================================
- ISO: ${OUTPUT_DIR}/RadiateOS-${VERSION}-amd64.iso
- Size: $(du -h ${OUTPUT_DIR}/RadiateOS-${VERSION}-amd64.iso 2>/dev/null | cut -f1)
- Kernel: 6.5.0-radiateos
- Architecture: x86_64
- GPU Support: NVIDIA (with CUDA)
- Touchscreen: Enabled
- Boot Mode: UEFI/Legacy BIOS

Features:
- Intel Core i7 optimizations
- NVIDIA GPU with CUDA support
- HP Pavilion touchscreen support
- Multi-touch gestures
- Secure Boot compatible
- Live USB with persistence
- Automatic hardware detection

Next Steps:
1. Create bootable USB (see instructions above)
2. Boot HP Pavilion from USB
3. Select "Boot RadiateOS" or "Install RadiateOS"
4. Follow on-screen instructions

Support:
- Touchscreen calibration: calibrate-touchscreen
- GPU status: nvidia-smi
- System info: neofetch

========================================
EOF
    
    log_info "Build completed successfully!"
    log_info "ISO location: ${OUTPUT_DIR}/RadiateOS-${VERSION}-amd64.iso"
}

# Handle errors
trap 'log_error "Build failed! Check logs for details."; exit 1' ERR

# Run main build
main "$@"