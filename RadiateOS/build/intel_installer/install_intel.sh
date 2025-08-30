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
