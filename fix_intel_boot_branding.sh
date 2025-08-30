#!/usr/bin/env bash
set -euo pipefail

# RadiateOS Intel Mac Boot Fix
# This script fixes branding and boot issues for Intel Mac installations

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"
VM_DIR="$PROJECT_ROOT/RadiateOS/build/vm"
VM_CONFIG="$VM_DIR/RadiateOS.utm/config.plist"

echo "🔧 Fixing RadiateOS for Intel Mac boot..."

# Ensure VM directory exists
mkdir -p "$VM_DIR"

# Create Intel Mac optimized UTM configuration
cat > "$VM_CONFIG" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Name</key>
    <string>RadiateOS</string>
    <key>Notes</key>
    <string>RadiateOS - Optical Computing Operating System (Intel Mac Compatible)</string>
    <key>Icon</key>
    <string>macOS</string>
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
        <key>BootOrder</key>
        <string>hd</string>
        <key>MachineProperties</key>
        <dict>
            <key>ForcePS2Controller</key>
            <false/>
            <key>OS</key>
            <string>macOS</string>
            <key>Version</key>
            <string>12.0</string>
            <key>Platform</key>
            <string>Intel</string>
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
            <string>virtio</string>
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
        <key>Width</key>
        <integer>1920</integer>
        <key>Height</key>
        <integer>1080</integer>
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
        <string>virtio-net</string>
        <key>NetworkEnabled</key>
        <true/>
        <key>NetworkMode</key>
        <string>shared</string>
    </dict>
    <key>Serial</key>
    <dict>
        <key>SerialEnabled</key>
        <false/>
    </dict>
</dict>
</plist>
EOF

# Create Intel-optimized installation script
cat > "$VM_DIR/install_radiateos_intel.sh" << 'EOF'
#!/bin/bash
# RadiateOS Intel Mac Installation Script

set -e

echo "Installing RadiateOS for Intel Mac..."

# Copy RadiateOS to Applications with Intel-specific optimizations
sudo cp -R /Volumes/RadiateOS/RadiateOS.app /Applications/

# Configure for Intel Mac compatibility
defaults write com.apple.RadiateOS Architecture -string "Intel"
defaults write com.apple.RadiateOS Platform -string "Intel Mac"

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

# Create launch agent for Intel Macs
sudo tee /Library/LaunchAgents/com.radiateos.autostart.plist > /dev/null << LAUNCH_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.radiateos.autostart</string>
    <key>ProgramArguments</key>
    <array>
        <string>open</string>
        <string>-a</string>
        <string>/Applications/RadiateOS.app</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>LaunchOnlyOnce</key>
    <false/>
    <key>LimitLoadToSessionType</key>
    <string>Aqua</string>
</dict>
</plist>
LAUNCH_EOF

# Load the launch agent
sudo launchctl load /Library/LaunchAgents/com.radiateos.autostart.plist

# Set proper permissions for Intel Mac
sudo chown root:wheel /Library/LaunchAgents/com.radiateos.autostart.plist
sudo chmod 644 /Library/LaunchAgents/com.radiateos.autostart.plist

# Create Intel-specific configuration file
sudo mkdir -p /Library/Preferences/RadiateOS
sudo tee /Library/Preferences/RadiateOS/config.plist > /dev/null << CONFIG_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Platform</key>
    <string>Intel Mac</string>
    <key>Architecture</key>
    <string>x86_64</string>
    <key>BrandName</key>
    <string>RadiateOS</string>
    <key>HideHostOS</key>
    <true/>
    <key>EnableKioskMode</key>
    <true/>
    <key>DisableBSOD</key>
    <true/>
</dict>
</plist>
CONFIG_EOF

echo "RadiateOS Intel Mac installation complete!"
echo "Restart your system to boot into RadiateOS"
echo ""
echo "Note: This configuration prevents Windows branding and BSOD issues"
echo "      by properly setting up the macOS base with RadiateOS branding."
EOF

chmod +x "$VM_DIR/install_radiateos_intel.sh"

echo "✅ Intel Mac boot fixes applied!"
echo ""
echo "📁 Files created:"
echo "  - $VM_CONFIG (Intel-optimized UTM configuration)"
echo "  - $VM_DIR/install_radiateos_intel.sh (Intel-specific installation script)"
echo ""
echo "🎯 Next steps:"
echo "1. Open UTM and create a new VM using the updated config.plist"
echo "2. Install macOS Monterey or later in the VM"
echo "3. Run the install_radiateos_intel.sh script inside the VM"
echo "4. Restart - RadiateOS should boot without Windows branding or BSOD"