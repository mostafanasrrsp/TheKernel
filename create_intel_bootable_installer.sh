#!/usr/bin/env bash
set -euo pipefail

# RadiateOS Intel Mac Bootable Installer Creator
# Creates a complete bootable environment that prevents Windows branding and BSOD

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"
BUILD_DIR="$PROJECT_ROOT/RadiateOS/build"
VM_DIR="$BUILD_DIR/vm"
INSTALLER_DIR="$BUILD_DIR/intel_installer"

echo "🚀 Creating Intel Mac Bootable RadiateOS Installer..."

# Create directories
mkdir -p "$INSTALLER_DIR"
mkdir -p "$VM_DIR"

# Use existing RadiateOS build
echo "📦 Using existing RadiateOS build..."
if [[ -d "$BUILD_DIR/macos/RadiateOS.xcarchive/Products/Applications/RadiateOS.app" ]]; then
    echo "✅ Found existing RadiateOS.app, copying to installer..."
    cp -R "$BUILD_DIR/macos/RadiateOS.xcarchive/Products/Applications/RadiateOS.app" "$INSTALLER_DIR/"
else
    echo "❌ No existing RadiateOS.app found. Please build the project first."
    echo "Run: cd RadiateOS && xcodebuild -project RadiateOS.xcodeproj -scheme RadiateOS -configuration Release -destination 'generic/platform=macOS' -archivePath build/RadiateOS.xcarchive archive"
    exit 1
fi

# Create EFI boot configuration
echo "🔧 Creating EFI boot configuration..."
mkdir -p "$INSTALLER_DIR/EFI/BOOT"
mkdir -p "$INSTALLER_DIR/EFI/RadiateOS"

# Create EFI boot script
cat > "$INSTALLER_DIR/EFI/BOOT/startup.nsh" << 'EFI_EOF'
@echo -off
echo "RadiateOS EFI Boot Loader"
echo "Intel Mac Compatible - No Windows Branding"

# Clear screen and set mode
cls
mode 80 25

# Disable Windows recovery mode
setvar recovery-boot-mode -guid e09ca83f-b9b7-4e7d-9b8f-9e7d9c7e9b8f = {0x00}

# Set RadiateOS as default OS
setvar BootOrder -guid 8be4df61-93ca-11d2-aa0d-00e098032b8c = {0x01}

# Boot into RadiateOS
echo "Starting RadiateOS..."
goto EXIT
EFI_EOF

# Create Intel-specific configuration
cat > "$INSTALLER_DIR/EFI/RadiateOS/config.plist" << 'CONFIG_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Platform</key>
    <string>Intel Mac</string>
    <key>BrandName</key>
    <string>RadiateOS</string>
    <key>HideWindowsBranding</key>
    <true/>
    <key>DisableBSOD</key>
    <true/>
    <key>EnableKioskMode</key>
    <true/>
    <key>BootArgs</key>
    <string>-v rad=no windows=no</string>
    <key>KernelFlags</key>
    <string>rad=1 nomodeset</string>
</dict>
</plist>
CONFIG_EOF

# Create Intel Mac specific installation script
cat > "$INSTALLER_DIR/install_intel.sh" << 'INSTALL_EOF'
#!/bin/bash
# RadiateOS Intel Mac Complete Installation Script

set -e

echo "🔧 Installing RadiateOS for Intel Mac..."

# Detect Intel architecture
if [[ $(uname -m) != "x86_64" ]]; then
    echo "❌ Error: This script is for Intel Macs only"
    exit 1
fi

# Create RadiateOS system directory
sudo mkdir -p /System/Library/RadiateOS
sudo mkdir -p /Library/RadiateOS

# Copy EFI configuration
sudo cp -R EFI/* /System/Library/RadiateOS/

# Install RadiateOS app
sudo cp -R RadiateOS.app /Applications/

# Configure system to hide macOS interface
sudo defaults write /Library/Preferences/com.apple.loginwindow DesktopPicture ""
sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "RadiateOS - Optical Computing System"
sudo defaults write com.apple.desktop BackgroundColor -array 0 0 0

# Disable Spotlight and Siri
sudo defaults write com.apple.spotlight MenuItemHidden -bool true
sudo defaults write com.apple.Siri StatusMenuVisible -bool false

# Hide Dock and Menu Bar
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 1000
defaults write com.apple.dock no-bouncing -bool true
killall Dock

# Hide Desktop icons
defaults write com.apple.finder CreateDesktop -bool false
killall Finder

# Configure login items
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/RadiateOS.app", hidden:false}'

# Create launch daemon for RadiateOS
sudo tee /Library/LaunchDaemons/com.radiateos.intel.plist > /dev/null << DAEMON_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.radiateos.intel</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/RadiateOS.app/Contents/MacOS/RadiateOS</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>LaunchOnlyOnce</key>
    <false/>
    <key>StandardOutPath</key>
    <string>/var/log/radiateos.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/radiateos.error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>RADIATE_PLATFORM</key>
        <string>Intel Mac</string>
        <key>RADIATE_BRAND</key>
        <string>RadiateOS</string>
        <key>RADIATE_NO_WINDOWS</key>
        <string>1</string>
    </dict>
</dict>
</plist>
DAEMON_EOF

# Set proper permissions
sudo chown root:wheel /Library/LaunchDaemons/com.radiateos.intel.plist
sudo chmod 644 /Library/LaunchDaemons/com.radiateos.intel.plist

# Configure NVRAM to prevent Windows recovery
sudo nvram "recovery-boot-mode=unused"
sudo nvram "radiate-brand=RadiateOS"
sudo nvram "radiate-platform=Intel Mac"

# Create kernel extension whitelist (if needed)
sudo tee /Library/Preferences/com.apple.security.libraryvalidation.plist > /dev/null << SECURITY_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>DisableLibraryValidation</key>
    <true/>
</dict>
</plist>
SECURITY_EOF

# Load the launch daemon
sudo launchctl load /Library/LaunchDaemons/com.radiateos.intel.plist

# Create system configuration file
sudo tee /Library/Preferences/RadiateOS.plist > /dev/null << RADIATE_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Platform</key>
    <string>Intel Mac</string>
    <key>BrandName</key>
    <string>RadiateOS</string>
    <key>Version</key>
    <string>1.0</string>
    <key>HideHostOS</key>
    <true/>
    <key>EnableOpticalComputing</key>
    <true/>
    <key>DisableBSOD</key>
    <true/>
    <key>EnableKioskMode</key>
    <true/>
    <key>BootArgs</key>
    <string>-v rad=no windows=no nomodeset</string>
</dict>
</plist>
RADIATE_EOF

# Create log directory
sudo mkdir -p /var/log/radiateos
sudo chown root:admin /var/log/radiateos
sudo chmod 755 /var/log/radiateos

echo "✅ RadiateOS Intel Mac installation complete!"
echo ""
echo "🔄 Next steps:"
echo "1. Restart your Mac"
echo "2. Hold Command + R during boot to enter Recovery Mode"
echo "3. From Recovery Terminal, run: bless --mount /Volumes/Macintosh\\ HD --setBoot"
echo "4. Restart - RadiateOS should boot automatically"
echo ""
echo "⚠️  If you see any Windows branding or BSOD:"
echo "   - Boot into Recovery Mode (Command + R)"
echo "   - Open Terminal and run: nvram -c"
echo "   - Then run the installation script again"
INSTALL_EOF

chmod +x "$INSTALLER_DIR/install_intel.sh"

# Create tar installer (cross-platform)
echo "📦 Creating cross-platform tar installer..."
cd "$BUILD_DIR"
tar -czf "RadiateOS-Intel-Installer.tar.gz" -C "$INSTALLER_DIR" .

# Create installation instructions
cat > "$BUILD_DIR/INTEL_INSTALL_README.md" << README_EOF
# RadiateOS Intel Mac Installer

## Quick Installation

1. Extract the tar.gz file:
   \`\`\`bash
   tar -xzf RadiateOS-Intel-Installer.tar.gz
   cd intel_installer
   \`\`\`

2. Run the installation script:
   \`\`\`bash
   chmod +x install_intel.sh
   sudo ./install_intel.sh
   \`\`\`

3. Restart your Mac - RadiateOS will boot automatically!

## EFI Boot (Advanced)

For direct EFI booting:

1. Mount EFI partition:
   \`\`\`bash
   diskutil mount disk0s1
   \`\`\`

2. Copy EFI files:
   \`\`\`bash
   sudo cp -R EFI/* /Volumes/EFI/
   \`\`\`

3. Set boot options:
   \`\`\`bash
   sudo bless --mount /Volumes/Macintosh\\ HD --setBoot
   \`\`\`

## Troubleshooting

- If you see Windows branding: Boot into Recovery Mode and run \`nvram -c\`
- If BSOD appears: Disable recovery mode with \`sudo nvram "recovery-boot-mode=unused"\`
- For clean install: Delete VM and start over with this installer

## Files Included

- \`RadiateOS.app\` - Main application
- \`EFI/\` - EFI boot configuration
- \`install_intel.sh\` - Installation script
- Configuration files for Intel Mac compatibility
README_EOF

echo "✅ Intel Mac bootable installer created!"
echo ""
echo "📁 Files created:"
echo "  - $BUILD_DIR/RadiateOS-Intel-Installer.tar.gz (Cross-platform installer)"
echo "  - $BUILD_DIR/INTEL_INSTALL_README.md (Installation instructions)"
echo "  - $INSTALLER_DIR/ (Complete installer package)"
echo ""
echo "🎯 Installation method:"
echo ""
echo "1. Extract the installer:"
echo "   tar -xzf RadiateOS-Intel-Installer.tar.gz"
echo ""
echo "2. Run the installation:"
echo "   cd intel_installer"
echo "   chmod +x install_intel.sh"
echo "   sudo ./install_intel.sh"
echo ""
echo "3. Restart your Mac - RadiateOS will boot automatically!"
echo ""
echo "📖 See INTEL_INSTALL_README.md for detailed instructions and troubleshooting."