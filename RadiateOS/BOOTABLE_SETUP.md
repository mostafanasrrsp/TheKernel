# RadiateOS Bootable Setup Guide

## 🚀 Creating a Bootable RadiateOS Environment

This guide will help you create a bootable version of RadiateOS using UTM (Virtual Machine) that can run as a standalone operating system.

## Prerequisites

1. **UTM** - Download from [mac.getutm.app](https://mac.getutm.app)
2. **macOS Installer** - Download from Apple's website or App Store
3. **RadiateOS Project** - This project built and ready

## Method 1: Automated VM Setup (Recommended)

### Step 1: Run the VM Creation Script

```bash
cd /Users/mostafanasr/Desktop/TheKernel/RadiateOS
./scripts/create_vm_image.sh
```

This script will:
- Build RadiateOS for release
- Create UTM configuration files
- Generate installation scripts
- Set up kiosk mode configuration

### Step 2: Create VM in UTM

1. Open UTM
2. Click "Create a New Virtual Machine"
3. Choose "Virtualize" (for macOS on Apple Silicon) or "Emulate" (for Intel)
4. Select "macOS 12+" as the operating system
5. Import the generated `config.plist` from `build/vm/RadiateOS.utm/`

### Step 3: Install macOS Base System

1. Boot the VM with macOS installer
2. Complete the standard macOS installation
3. Create a user account (temporary - will be hidden later)
4. Complete initial setup

### Step 4: Install RadiateOS

1. Copy the `build/vm/install_radiateos.sh` script to the VM
2. Run the installation script:
   ```bash
   chmod +x install_radiateos.sh
   ./install_radiateos.sh
   ```

### Step 5: Configure Kiosk Mode

The installation script automatically:
- Hides the macOS Dock and Menu Bar
- Sets RadiateOS to launch at startup
- Disables desktop icons
- Creates a launch daemon for RadiateOS

### Step 6: Restart and Boot into RadiateOS

Restart the VM - RadiateOS will now launch automatically as the primary interface!

## Method 2: Manual Setup

### Creating a Custom macOS Image

1. **Download macOS Installer**
   ```bash
   # Download macOS Monterey or later
   softwareupdate --fetch-full-installer --full-installer-version 12.6.1
   ```

2. **Build RadiateOS**
   ```bash
   ./scripts/build_macos_dmg.sh
   ```

3. **Create VM in UTM**
   - Memory: 4GB minimum (8GB recommended)
   - Storage: 64GB minimum
   - Display: Retina resolution
   - Enable hardware acceleration

4. **Install Base System**
   - Boot from macOS installer
   - Install to VM disk
   - Skip user setup (we'll configure this)

5. **Configure Kiosk Environment**
   ```bash
   # Hide Dock permanently
   defaults write com.apple.dock autohide -bool true
   defaults write com.apple.dock autohide-delay -float 1000
   
   # Hide desktop
   defaults write com.apple.finder CreateDesktop false
   
   # Set RadiateOS as login item
   osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/RadiateOS.app", hidden:false}'
   ```

## Development Environment Setup

RadiateOS now includes built-in development tools:

### Available Development Apps
- **Code Editor** - Full-featured code editor with syntax highlighting
- **Swift Compiler** - Build and compile Swift projects
- **Package Manager** - Install and manage Swift packages
- **Terminal** - Full terminal access for development

### Self-Improvement Workflow

1. **Boot into RadiateOS**
2. **Open Code Editor** from the dock or desktop
3. **Edit RadiateOS source code** directly within the OS
4. **Use Swift Compiler** to build changes
5. **Test immediately** - changes take effect on next app launch

### Development Features
- **Real-time code editing** within RadiateOS
- **Integrated build system** with optical computing optimizations
- **Package management** for adding new capabilities
- **Terminal access** for advanced development tasks

## Bootable Features

### What Works in Bootable Mode
✅ Full desktop environment
✅ Window management
✅ All built-in applications
✅ File system access
✅ Development tools
✅ Network connectivity (through VM)
✅ Self-modification capabilities

### Optical Computing Simulation
- **Photonic CPU simulation** with realistic performance metrics
- **Quantum-encrypted connections** in Safari
- **Neural tab management** and AI-assisted features
- **Optical memory management** with advanced algorithms

## Troubleshooting

### VM Won't Boot
- Ensure sufficient RAM (4GB minimum)
- Check that hardware acceleration is enabled
- Verify macOS installer is compatible

### RadiateOS Doesn't Launch
- Check that the app was copied to `/Applications/`
- Verify launch daemon is loaded: `sudo launchctl list | grep radiateos`
- Check console logs for errors

### Development Tools Not Working
- Ensure file system permissions are correct
- Check that Xcode Command Line Tools are installed in the base system
- Verify network connectivity for package downloads

## Performance Tips

### Optimizing VM Performance
- Allocate maximum CPU cores
- Enable hardware acceleration
- Use SSD storage for VM disk
- Allocate sufficient RAM (8GB+ recommended)

### RadiateOS Optimizations
- The OS includes optical computing optimizations
- Photonic rendering acceleration
- Neural network-based UI predictions
- Quantum-encrypted data storage

## Creating Compressed Images

To create a compressed version for distribution:

```bash
# Create compressed VM image
cd build/vm
tar -czf RadiateOS-Bootable.tar.gz RadiateOS.utm/

# Create installer package
hdiutil create -volname "RadiateOS Installer" \
  -srcfolder . -ov -format UDZO \
  RadiateOS-Installer.dmg
```

## Next Steps

Once you have RadiateOS running in bootable mode:

1. **Explore the OS** - Try all applications and features
2. **Develop within RadiateOS** - Use the built-in development tools
3. **Customize the experience** - Modify the OS to your needs
4. **Share your creation** - Export and distribute your custom OS

## Advanced Configuration

### Custom Boot Animation
Edit `RadiateOS/SetupWizard/LaunchScreenView.swift` to customize the boot sequence.

### Adding New Applications
Use the Package Manager or Code Editor to develop new applications directly within RadiateOS.

### Networking Configuration
Configure network settings through System Preferences to enable internet access for development.

---

**Congratulations!** You now have a fully bootable RadiateOS environment with development capabilities. You can now run apps, develop new features, and even improve the OS itself - all from within RadiateOS!
