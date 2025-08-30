# RadiateOS Installation Guide

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Installation Methods](#installation-methods)
3. [Platform-Specific Instructions](#platform-specific-instructions)
4. [Post-Installation Setup](#post-installation-setup)
5. [Troubleshooting](#troubleshooting)

## System Requirements

### Minimum Requirements
- **CPU**: 64-bit processor with at least 2 cores
- **RAM**: 8GB
- **Storage**: 20GB free space
- **Graphics**: OpenGL 3.3 compatible
- **Network**: Ethernet or Wi-Fi for updates

### Recommended Requirements
- **CPU**: 64-bit processor with 4+ cores
- **RAM**: 16GB or more
- **Storage**: 50GB free space on SSD
- **Graphics**: Dedicated GPU with 4GB VRAM
- **Network**: Gigabit Ethernet

## Installation Methods

### Method 1: Direct Installation (Recommended)

#### macOS
```bash
# Download the installer
curl -L https://radiateos.com/download/mac -o RadiateOS-Installer.dmg

# Mount the DMG
hdiutil attach RadiateOS-Installer.dmg

# Run the installer
/Volumes/RadiateOS/Install\ RadiateOS.app/Contents/MacOS/Install\ RadiateOS
```

#### Linux (Ubuntu/Debian)
```bash
# Add RadiateOS repository
sudo add-apt-repository ppa:radiateos/stable
sudo apt update

# Install RadiateOS
sudo apt install radiateos

# Launch RadiateOS
radiateos
```

#### Windows (WSL2)
```powershell
# Enable WSL2
wsl --install

# Install Ubuntu
wsl --install -d Ubuntu

# Follow Linux installation steps
wsl -d Ubuntu
```

### Method 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/radiateos/TheKernel.git
cd TheKernel

# Install dependencies
./scripts/install_dependencies.sh

# Build RadiateOS
./build_and_package.sh

# Install
sudo ./install.sh
```

### Method 3: Bootable USB Installation

#### Creating Bootable USB

1. **Download the ISO**
   ```bash
   wget https://radiateos.com/download/RadiateOS-1.0.0.iso
   ```

2. **Prepare USB Drive** (minimum 8GB)
   ```bash
   # Find your USB device
   diskutil list  # macOS
   lsblk          # Linux
   
   # Create bootable USB (replace /dev/diskX with your device)
   sudo dd if=RadiateOS-1.0.0.iso of=/dev/diskX bs=4M status=progress
   ```

3. **Boot from USB**
   - Restart your computer
   - Enter BIOS/UEFI (usually F2, F12, or DEL key)
   - Select USB as boot device
   - Follow on-screen installation wizard

## Platform-Specific Instructions

### macOS Installation

#### Intel Macs
```bash
# Check compatibility
system_profiler SPHardwareDataType | grep "Processor Name"

# Download Intel-specific build
curl -L https://radiateos.com/download/mac-intel -o RadiateOS-Intel.dmg

# Install
hdiutil attach RadiateOS-Intel.dmg
cp -R /Volumes/RadiateOS/RadiateOS.app /Applications/
```

#### Apple Silicon (M1/M2/M3)
```bash
# Download ARM build
curl -L https://radiateos.com/download/mac-arm -o RadiateOS-ARM.dmg

# Install with Rosetta support
softwareupdate --install-rosetta --agree-to-license
hdiutil attach RadiateOS-ARM.dmg
cp -R /Volumes/RadiateOS/RadiateOS.app /Applications/
```

### Linux Installation

#### Ubuntu/Debian
```bash
# Install required packages
sudo apt update
sudo apt install -y build-essential git cmake libssl-dev

# Download and extract
wget https://radiateos.com/download/linux/radiateos-linux-x64.tar.gz
tar -xzf radiateos-linux-x64.tar.gz

# Install
cd radiateos-linux-x64
sudo ./install.sh

# Add to PATH
echo 'export PATH=$PATH:/opt/radiateos/bin' >> ~/.bashrc
source ~/.bashrc
```

#### Fedora/RHEL
```bash
# Install dependencies
sudo dnf install -y gcc gcc-c++ make cmake openssl-devel

# Download RPM package
wget https://radiateos.com/download/linux/radiateos-1.0.0.rpm

# Install
sudo rpm -i radiateos-1.0.0.rpm
```

#### Arch Linux
```bash
# Install from AUR
yay -S radiateos

# Or build manually
git clone https://aur.archlinux.org/radiateos.git
cd radiateos
makepkg -si
```

### PC/Windows Native (Experimental)

```powershell
# Download installer
Invoke-WebRequest -Uri "https://radiateos.com/download/windows/RadiateOS-Setup.exe" -OutFile "RadiateOS-Setup.exe"

# Run installer as Administrator
Start-Process -FilePath "RadiateOS-Setup.exe" -Verb RunAs

# Or use Chocolatey
choco install radiateos
```

## Post-Installation Setup

### Initial Configuration

1. **Launch RadiateOS**
   ```bash
   radiateos --first-run
   ```

2. **Complete Setup Wizard**
   - Choose language and region
   - Configure network settings
   - Create user account
   - Set up security preferences

3. **Update System**
   ```bash
   radiateos --update
   ```

### Essential Configuration

#### Enable GPU Acceleration
```bash
# For NVIDIA
radiateos --gpu nvidia --enable-cuda

# For AMD
radiateos --gpu amd --enable-rocm

# For Intel
radiateos --gpu intel --enable-oneapi
```

#### Configure Memory Settings
```bash
# Set memory allocation
radiateos config set memory.allocation dynamic
radiateos config set memory.max_usage 75%

# Enable memory compression
radiateos config set memory.compression true
```

#### Network Configuration
```bash
# Configure network interfaces
radiateos network configure eth0 --dhcp
radiateos network configure wlan0 --ssid "YourNetwork" --password "YourPassword"

# Enable optical network protocols
radiateos network enable-optical
```

## Verification

### Verify Installation
```bash
# Check version
radiateos --version

# Run system check
radiateos doctor

# Verify kernel modules
radiateos kernel status

# Test optical CPU
radiateos test optical-cpu

# Benchmark system
radiateos benchmark --full
```

### Expected Output
```
RadiateOS Version: 1.0.0
Kernel: Optical-5.15
CPU: Optical Processing Unit (OPU) - 8 cores @ 3.0 THz
Memory: 16GB DDR5 with optical interconnect
Storage: 512GB NVMe with photonic controller
GPU: Integrated Optical Graphics
Status: All systems operational
```

## Troubleshooting

### Common Issues

#### Installation Fails
```bash
# Check logs
cat /var/log/radiateos/install.log

# Clear cache and retry
rm -rf ~/.radiateos/cache
sudo apt clean  # or equivalent for your distro
```

#### Boot Issues
```bash
# Boot in safe mode
radiateos --safe-mode

# Reset configuration
radiateos --reset-config

# Rebuild kernel modules
radiateos kernel rebuild
```

#### Performance Issues
```bash
# Disable visual effects
radiateos config set graphics.effects minimal

# Optimize for performance
radiateos optimize --performance

# Check resource usage
radiateos monitor
```

#### GPU Not Detected
```bash
# Reinstall GPU drivers
radiateos gpu install-drivers

# Force GPU detection
radiateos gpu detect --force

# Use fallback renderer
radiateos config set graphics.renderer software
```

### Getting Help

- **Documentation**: https://docs.radiateos.com
- **Community Forum**: https://forum.radiateos.com
- **Discord**: https://discord.gg/radiateos
- **Email Support**: support@radiateos.com

## Uninstallation

### macOS
```bash
# Remove application
rm -rf /Applications/RadiateOS.app
rm -rf ~/Library/Application\ Support/RadiateOS
rm -rf ~/Library/Preferences/com.radiateos.*
```

### Linux
```bash
# Using package manager
sudo apt remove radiateos  # Debian/Ubuntu
sudo dnf remove radiateos  # Fedora
sudo pacman -R radiateos   # Arch

# Manual removal
sudo rm -rf /opt/radiateos
rm -rf ~/.radiateos
```

### Windows
```powershell
# Using Control Panel
# Go to Settings > Apps > RadiateOS > Uninstall

# Or using PowerShell
Get-Package -Name RadiateOS | Uninstall-Package
```

## Next Steps

After successful installation:
1. Read the [User Guide](USER_GUIDE.md)
2. Explore [System Features](FEATURES.md)
3. Join our [Community](https://community.radiateos.com)
4. Report issues on [GitHub](https://github.com/radiateos/TheKernel/issues)

---

**Note**: RadiateOS is under active development. Please report any installation issues to help us improve the process.