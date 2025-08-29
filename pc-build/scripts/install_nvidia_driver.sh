#!/bin/bash
# NVIDIA Driver Installation for RadiateOS

set -e

NVIDIA_VERSION="545.29.06"
CUDA_VERSION="12.3"

echo "======================================"
echo "RadiateOS NVIDIA Driver Installer"
echo "Version: ${NVIDIA_VERSION}"
echo "CUDA: ${CUDA_VERSION}"
echo "======================================"

# Colors
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

# Check for NVIDIA GPU
log_info "Detecting NVIDIA GPU..."
if ! lspci | grep -i nvidia > /dev/null; then
    log_error "No NVIDIA GPU detected!"
    exit 1
fi

GPU_INFO=$(lspci | grep -i nvidia)
log_info "Found GPU: ${GPU_INFO}"

# Blacklist nouveau driver
log_info "Blacklisting nouveau driver..."
cat > /etc/modprobe.d/blacklist-nouveau.conf << EOF
blacklist nouveau
options nouveau modeset=0
EOF

# Update initramfs
update-initramfs -u

# Download NVIDIA driver
log_info "Downloading NVIDIA driver ${NVIDIA_VERSION}..."
cd /tmp
wget -q https://us.download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_VERSION}/NVIDIA-Linux-x86_64-${NVIDIA_VERSION}.run

# Make executable
chmod +x NVIDIA-Linux-x86_64-${NVIDIA_VERSION}.run

# Install driver
log_info "Installing NVIDIA driver..."
./NVIDIA-Linux-x86_64-${NVIDIA_VERSION}.run \
    --silent \
    --no-questions \
    --accept-license \
    --disable-nouveau \
    --no-cc-version-check \
    --install-libglvnd

# Configure X11 for NVIDIA
log_info "Configuring display server..."
nvidia-xconfig --allow-empty-initial-configuration

# Install CUDA toolkit
log_info "Installing CUDA toolkit..."
wget -q https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
dpkg -i cuda-keyring_1.0-1_all.deb
apt-get update
apt-get install -y cuda-toolkit-${CUDA_VERSION//./-}

# Configure environment
cat >> /etc/environment << EOF
PATH="/usr/local/cuda/bin:\${PATH}"
LD_LIBRARY_PATH="/usr/local/cuda/lib64:\${LD_LIBRARY_PATH}"
EOF

# Enable persistence mode
nvidia-smi -pm 1

# Create NVIDIA settings file
cat > /etc/X11/xorg.conf.d/20-nvidia.conf << EOF
Section "Device"
    Identifier     "Device0"
    Driver         "nvidia"
    VendorName     "NVIDIA Corporation"
    Option         "NoLogo" "1"
    Option         "Coolbits" "31"
    Option         "TripleBuffer" "true"
    Option         "RegistryDwords" "PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerDefault=0x1; PowerMizerDefaultAC=0x1"
EndSection

Section "Screen"
    Identifier     "Screen0"
    Device         "Device0"
    Monitor        "Monitor0"
    DefaultDepth    24
    Option         "Stereo" "0"
    Option         "nvidiaXineramaInfoOrder" "DFP-0"
    Option         "metamodes" "nvidia-auto-select +0+0 {ForceCompositionPipeline=On}"
    Option         "AllowIndirectGLXProtocol" "off"
    SubSection     "Display"
        Depth       24
    EndSubSection
EndSection
EOF

# Verify installation
log_info "Verifying NVIDIA installation..."
nvidia-smi

log_info "NVIDIA driver installation complete!"
log_info "Driver Version: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader)"
log_info "CUDA Version: $(nvcc --version | grep release | awk '{print $6}')"

echo "======================================"
echo "Installation Complete!"
echo "Please reboot to activate the driver"
echo "======================================="