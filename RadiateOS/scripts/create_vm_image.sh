#!/usr/bin/env bash
set -euo pipefail

# RadiateOS VM Image Creator
# This script creates a bootable VM image for UTM with RadiateOS as the primary interface

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/vm"
VM_NAME="RadiateOS"
VM_DIR="$BUILD_DIR/$VM_NAME.utm"

echo "🚀 Creating RadiateOS VM Image..."

# Create build directory
mkdir -p "$BUILD_DIR"
rm -rf "$VM_DIR"

# Build RadiateOS for release
echo "📦 Building RadiateOS..."
cd "$PROJECT_ROOT"
xcodebuild -project RadiateOS.xcodeproj -scheme RadiateOS -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$BUILD_DIR/RadiateOS.xcarchive" \
  archive

# Export the app
echo "📤 Exporting RadiateOS app..."
xcodebuild -exportArchive \
  -archivePath "$BUILD_DIR/RadiateOS.xcarchive" \
  -exportPath "$BUILD_DIR/export" \
  -exportOptionsPlist "$SCRIPT_DIR/export_options.plist"

# Create VM structure
echo "🖥️  Creating VM structure..."
mkdir -p "$VM_DIR"

# Create UTM configuration
cat > "$VM_DIR/config.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Name</key>
    <string>RadiateOS</string>
    <key>Notes</key>
    <string>RadiateOS - Optical Computing Operating System</string>
    <key>Architecture</key>
    <string>x86_64</string>
    <key>Backend</key>
    <string>qemu</string>
    <key>System</key>
    <dict>
        <key>MemorySize</key>
        <integer>4096</integer>
        <key>CPUCount</key>
        <integer>2</integer>
        <key>BootDevice</key>
        <string>hd</string>
        <key>MachineProperties</key>
        <dict>
            <key>ForcePS2Controller</key>
            <false/>
        </dict>
    </dict>
    <key>Drives</key>
    <array>
        <dict>
            <key>ImagePath</key>
            <string>disk.qcow2</string>
            <key>ImageType</key>
            <string>qcow2</string>
            <key>Interface</key>
            <string>ide</string>
            <key>Removable</key>
            <false/>
        </dict>
    </array>
    <key>Display</key>
    <dict>
        <key>DisplayCard</key>
        <string>virtio-vga-gl</string>
        <key>DisplayDownscaler</key>
        <string>linear</string>
        <key>DisplayUpscaler</key>
        <string>linear</string>
    </dict>
    <key>Input</key>
    <dict>
        <key>InputLegacy</key>
        <false/>
        <key>InputInvert</key>
        <false/>
    </dict>
    <key>Sound</key>
    <dict>
        <key>SoundCard</key>
        <string>intel-hda</string>
        <key>SoundEnabled</key>
        <true/>
    </dict>
    <key>Network</key>
    <dict>
        <key>NetworkCard</key>
        <string>rtl8139</string>
        <key>NetworkEnabled</key>
        <true/>
        <key>NetworkMode</key>
        <string>shared</string>
    </dict>
</dict>
</plist>
EOF

# Create startup script for kiosk mode
echo "🎯 Creating kiosk mode configuration..."
mkdir -p "$BUILD_DIR/kiosk"

cat > "$BUILD_DIR/kiosk/com.radiateos.kiosk.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.radiateos.kiosk</string>
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
</dict>
</plist>
EOF

# Create installation script
cat > "$BUILD_DIR/install_radiateos.sh" << 'EOF'
#!/bin/bash
# RadiateOS Installation Script for VM

set -e

echo "Installing RadiateOS..."

# Copy RadiateOS to Applications
sudo cp -R /Volumes/RadiateOS/RadiateOS.app /Applications/

# Hide Dock and Menu Bar (Kiosk Mode)
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 1000
defaults write com.apple.dock no-bouncing -bool true
killall Dock

# Hide Desktop icons
defaults write com.apple.finder CreateDesktop -bool false
killall Finder

# Set RadiateOS as login item
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/RadiateOS.app", hidden:false}'

# Create kiosk launch agent
sudo cp /Volumes/RadiateOS/com.radiateos.kiosk.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/com.radiateos.kiosk.plist

echo "RadiateOS installation complete!"
echo "Restart the system to boot into RadiateOS"
EOF

chmod +x "$BUILD_DIR/install_radiateos.sh"

echo "✅ VM image structure created at: $VM_DIR"
echo ""
echo "🎯 Next Steps:"
echo "1. Download macOS installer from Apple"
echo "2. Create a new VM in UTM using the config.plist"
echo "3. Install macOS in the VM"
echo "4. Run the install_radiateos.sh script inside the VM"
echo "5. RadiateOS will launch automatically on startup"
echo ""
echo "📁 Files created:"
echo "  - $VM_DIR/config.plist (UTM configuration)"
echo "  - $BUILD_DIR/install_radiateos.sh (Installation script)"
echo "  - $BUILD_DIR/kiosk/com.radiateos.kiosk.plist (Kiosk mode configuration)"
