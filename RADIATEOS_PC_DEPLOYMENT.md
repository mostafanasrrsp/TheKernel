# RadiateOS PC Deployment Guide
## HP Pavilion with Intel Core i7 & NVIDIA GPU

---

## 🚀 Quick Start

### Immediate Deployment (5 minutes)

```bash
# Clone and build
git clone <your-repo>
cd radiateos
sudo chmod +x quick_deploy_hp_pavilion.sh
sudo ./quick_deploy_hp_pavilion.sh
```

This will automatically:
- Build the OS
- Create bootable ISO
- Optionally create USB installer

---

## 📋 System Requirements

### Minimum Hardware
- **CPU**: Intel Core i5 or better (optimized for i7)
- **RAM**: 4GB minimum (8GB recommended)
- **Storage**: 20GB minimum
- **GPU**: NVIDIA GeForce (optional, but optimized)
- **Display**: Touchscreen supported

### Supported Features
- ✅ Intel Core i7 optimizations
- ✅ NVIDIA GPU with CUDA support
- ✅ Touchscreen with multi-touch gestures
- ✅ UEFI and Legacy BIOS boot
- ✅ Secure Boot compatible
- ✅ Live USB with persistence

---

## 🛠️ Installation Methods

### Method 1: USB Installation (Recommended)

1. **Build the ISO**:
```bash
sudo ./build_radiateos_pc.sh
```

2. **Create Bootable USB**:
```bash
# Find your USB device
lsblk

# Write ISO to USB (replace sdX with your device)
sudo dd if=output/RadiateOS-1.0.0-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

3. **Boot from USB**:
- Insert USB into HP Pavilion
- Power on and press **F9** or **ESC**
- Select USB from boot menu
- Choose "Install RadiateOS"

### Method 2: Direct Installation

```bash
# Run automated installer
sudo ./install_hp_pavilion.sh
```

### Method 3: Virtual Machine Testing

1. Create VM with:
   - Type: Linux (Ubuntu 64-bit)
   - RAM: 4GB minimum
   - Storage: 20GB
   - Enable: 3D Acceleration

2. Mount ISO and boot

---

## ⚙️ BIOS/UEFI Configuration

### HP Pavilion BIOS Settings (Press F10)

1. **Boot Configuration**:
   - Secure Boot: Disabled (for initial install)
   - Legacy Support: Enabled
   - Boot Order: USB First

2. **Advanced Settings**:
   - Virtualization: Enabled
   - Hyper-Threading: Enabled
   - Turbo Boost: Enabled

3. **Graphics**:
   - Primary Display: PCIe
   - DVMT Pre-Allocated: 128MB

---

## 🎮 NVIDIA GPU Setup

### Automatic Installation
The installer automatically detects and configures NVIDIA GPUs.

### Manual Configuration
```bash
# Check GPU status
nvidia-smi

# Install drivers manually if needed
sudo ./pc-build/scripts/install_nvidia_driver.sh

# Configure CUDA
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

### Performance Optimization
```bash
# Enable maximum performance
sudo nvidia-smi -pm 1
sudo nvidia-smi -pl 300  # Set power limit (adjust as needed)
```

---

## 👆 Touchscreen Configuration

### Automatic Setup
Touchscreen is auto-detected and configured during installation.

### Calibration
```bash
# Calibrate touchscreen
calibrate-touchscreen

# Test touchscreen
test-touchscreen
```

### Gestures
- **3-finger swipe up**: Activities overview
- **3-finger swipe down**: Show desktop
- **2-finger pinch**: Zoom
- **2-finger rotate**: Rotate (in supported apps)
- **Long press**: Right-click

---

## 🏗️ Building from Source

### Prerequisites
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Install build tools
sudo apt-get update
sudo apt-get install -y git build-essential
```

### Build Process
```bash
# 1. Build Docker image
cd pc-build
docker build -t radiateos-builder:1.0.0 .

# 2. Build kernel
docker run --rm -v $(pwd):/workspace radiateos-builder:1.0.0 \
    /workspace/pc-build/scripts/build_kernel.sh

# 3. Create ISO
docker run --rm --privileged -v $(pwd):/workspace radiateos-builder:1.0.0 \
    /workspace/pc-build/scripts/create_iso.sh
```

---

## 🔧 Post-Installation

### First Boot
1. System will auto-configure hardware
2. Create user account (if not auto-login)
3. Connect to WiFi
4. Update system:
```bash
sudo apt update && sudo apt upgrade
```

### Essential Commands
```bash
# System information
neofetch

# GPU monitoring
nvidia-smi
watch -n 1 nvidia-smi

# Touchscreen calibration
calibrate-touchscreen

# Display configuration
xrandr

# Network configuration
nmtui
```

### Installing Additional Software
```bash
# Development tools
sudo apt install code vim git

# Multimedia
sudo apt install vlc gimp audacity

# System tools
sudo apt install htop iotop nethogs
```

---

## 🐛 Troubleshooting

### Boot Issues
```bash
# If system won't boot, try:
# 1. Boot with nomodeset
# Add 'nomodeset' to GRUB boot parameters

# 2. Recovery mode
# Select "Advanced options" > "Recovery mode" from GRUB
```

### GPU Issues
```bash
# If NVIDIA driver fails
sudo apt purge nvidia-*
sudo ./pc-build/scripts/install_nvidia_driver.sh

# Fallback to nouveau
sudo apt install xserver-xorg-video-nouveau
```

### Touchscreen Issues
```bash
# Reconfigure touchscreen
sudo ./pc-build/scripts/configure_touchscreen.sh

# Check input devices
xinput list
evtest
```

### Network Issues
```bash
# Restart network
sudo systemctl restart NetworkManager

# Configure manually
sudo nmcli device wifi connect "SSID" password "PASSWORD"
```

---

## 📊 Performance Tuning

### CPU Governor
```bash
# Set to performance mode
sudo cpupower frequency-set -g performance

# Check current governor
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

### GPU Performance
```bash
# Maximum performance
sudo nvidia-smi -pm 1
sudo nvidia-smi -ac 5001,1506  # Memory,Graphics clocks

# Power saving
sudo nvidia-smi -pl 150  # Lower power limit
```

### System Optimization
```bash
# Disable unnecessary services
sudo systemctl disable bluetooth  # If not using Bluetooth
sudo systemctl disable cups       # If not printing

# Optimize swappiness
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
```

---

## 🔐 Security

### Firewall
```bash
# Enable firewall
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

### Updates
```bash
# Enable automatic security updates
sudo dpkg-reconfigure unattended-upgrades
```

---

## 📱 Remote Access

### SSH Server
```bash
sudo apt install openssh-server
sudo systemctl enable ssh
```

### VNC Server
```bash
sudo apt install x11vnc
x11vnc -storepasswd
x11vnc -forever -usepw -display :0
```

---

## 💾 Backup & Recovery

### System Backup
```bash
# Create system image
sudo dd if=/dev/sda of=/backup/radiateos.img bs=4M status=progress
```

### Recovery USB
```bash
# Keep installation USB as recovery media
# Boot from USB and select "Recovery Mode"
```

---

## 📞 Support

### Logs
```bash
# System logs
journalctl -xe

# Kernel logs
dmesg | less

# GPU logs
nvidia-bug-report.sh
```

### System Information
```bash
# Hardware info
sudo lshw -short

# PCI devices
lspci -v

# USB devices
lsusb -v

# Input devices
xinput list
```

---

## 🎯 Quick Reference

| Task | Command |
|------|---------|
| Build ISO | `sudo ./build_radiateos_pc.sh` |
| Create USB | `sudo dd if=output/RadiateOS.iso of=/dev/sdX bs=4M` |
| Install | `sudo ./install_hp_pavilion.sh` |
| GPU Status | `nvidia-smi` |
| Calibrate Touch | `calibrate-touchscreen` |
| System Info | `neofetch` |
| Update System | `sudo apt update && sudo apt upgrade` |

---

## ✅ Verification Checklist

After installation, verify:
- [ ] System boots successfully
- [ ] Graphics display properly
- [ ] Touchscreen responds
- [ ] Audio works
- [ ] WiFi connects
- [ ] NVIDIA GPU detected (`nvidia-smi`)
- [ ] All CPU cores active (`htop`)
- [ ] Gestures work

---

## 🚨 Emergency Recovery

If system becomes unbootable:
1. Boot from RadiateOS USB
2. Select "Recovery Mode"
3. Mount system partition
4. Chroot and repair:
```bash
mount /dev/sda3 /mnt
mount /dev/sda1 /mnt/boot/efi
chroot /mnt
# Repair system
update-grub
update-initramfs -u
exit
reboot
```

---

## 📈 Next Steps

1. **Customize Desktop**: Install themes and extensions
2. **Development Setup**: Install your development tools
3. **Performance Tuning**: Optimize for your specific workload
4. **Security Hardening**: Configure firewall and security policies

---

**RadiateOS v1.0.0** - Built for HP Pavilion  
Optimized for Intel Core i7 + NVIDIA GPU  
© 2024 RadiateOS Project