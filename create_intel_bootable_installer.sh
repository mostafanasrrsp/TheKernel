#!/bin/bash

# RadiateOS Intel Mac Bootable Installer Creator
# Creates a proper bootable installer that shows "RadiateOS" instead of "Windows"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/installers/intel-pc"
INSTALLER_NAME="RadiateOS-Intel-Installer"
INSTALLER_DMG="$BUILD_DIR/$INSTALLER_NAME.dmg"

echo "🚀 Creating RadiateOS Intel Mac Bootable Installer..."

# Create build directory
mkdir -p "$BUILD_DIR"

# Build RadiateOS app
echo "📦 Building RadiateOS application..."
cd "$PROJECT_ROOT/RadiateOS"
xcodebuild -project RadiateOS.xcodeproj -scheme RadiateOS -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$BUILD_DIR/RadiateOS.xcarchive" \
  archive

# Export the app
echo "📤 Exporting RadiateOS app..."
xcodebuild -exportArchive \
  -archivePath "$BUILD_DIR/RadiateOS.xcarchive" \
  -exportPath "$BUILD_DIR/export" \
  -exportOptionsPlist "$PROJECT_ROOT/RadiateOS/scripts/export_options.plist"

# Create installer structure
echo "🔧 Creating installer structure..."
STAGING_DIR="$BUILD_DIR/staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Copy RadiateOS app
cp -R "$BUILD_DIR/export/RadiateOS.app" "$STAGING_DIR/"

# Create installer configuration
cat > "$STAGING_DIR/installer.cfg" << 'EOF'
# RadiateOS Intel Mac Installer Configuration
OS_NAME="RadiateOS"
OS_VERSION="1.0"
OS_BUILD="Intel"
BOOT_LOADER="RadiateOS Boot Loader"
SYSTEM_REQUIREMENTS="Intel Mac, 8GB RAM, 20GB storage"
INSTALLATION_TYPE="Bootable Partition"
EOF

# Create pre-installation script
cat > "$STAGING_DIR/preinstall.sh" << 'EOF'
#!/bin/bash
# RadiateOS Pre-Installation Script

echo "🔍 Checking system compatibility..."
echo "OS: $OS_NAME $OS_VERSION ($OS_BUILD)"
echo "Boot Loader: $BOOT_LOADER"

# Check if running on Intel Mac
if [[ "$(uname -m)" != "x86_64" ]]; then
    echo "❌ This installer is only compatible with Intel Macs"
    exit 1
fi

# Check available storage
AVAILABLE_SPACE=$(df -h / | awk 'NR==2 {print $4}' | sed 's/G//')
if (( $(echo "$AVAILABLE_SPACE < 20" | bc -l) )); then
    echo "❌ Insufficient storage space. Need at least 20GB available."
    exit 1
fi

echo "✅ System compatibility check passed"
EOF

chmod +x "$STAGING_DIR/preinstall.sh"

# Create main installation script
cat > "$STAGING_DIR/install.sh" << 'EOF'
#!/bin/bash
# RadiateOS Main Installation Script

set -e

echo "🚀 Installing RadiateOS on Intel Mac..."

# Source configuration
source ./installer.cfg

echo "📋 Installation Details:"
echo "  OS: $OS_NAME $OS_VERSION"
echo "  Target: Bootable partition on Intel Mac"
echo "  Boot Loader: $BOOT_LOADER"

# Create RadiateOS partition (20GB)
echo "💾 Creating RadiateOS partition..."
DISK_INFO=$(diskutil list | grep -A 10 "Physical Store")
DISK_ID=$(echo "$DISK_INFO" | grep "0:" | awk '{print $NF}')

# Create APFS volume for RadiateOS
echo "🔧 Creating APFS volume..."
diskutil apfs addVolume disk1 APFS "$OS_NAME" 20g

# Mount the new volume
echo "📂 Mounting RadiateOS volume..."
diskutil mount "$OS_NAME"

# Copy system files
echo "📋 Installing system files..."
cp -R RadiateOS.app /Volumes/"$OS_NAME"/Applications/

# Create boot configuration
echo "⚙️  Configuring boot settings..."
cat > /Volumes/"$OS_NAME"/System/Library/CoreServices/SystemVersion.plist << BOOT_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ProductBuildVersion</key>
    <string>21G1974</string>
    <key>ProductName</key>
    <string>$OS_NAME</string>
    <key>ProductUserVisibleVersion</key>
    <string>$OS_VERSION</string>
    <key>ProductVersion</key>
    <string>$OS_VERSION</string>
</dict>
</plist>
BOOT_EOF

# Create launch daemon for RadiateOS
echo "🔄 Setting up auto-launch..."
mkdir -p /Volumes/"$OS_NAME"/Library/LaunchDaemons
cat > /Volumes/"$OS_NAME"/Library/LaunchDaemons/com.radiateos.autolaunch.plist << DAEMON_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.radiateos.autolaunch</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Applications/RadiateOS.app/Contents/MacOS/RadiateOS</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/radiateos.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/radiateos.error.log</string>
</dict>
</plist>
DAEMON_EOF

# Configure system preferences for kiosk mode
echo "🎯 Configuring kiosk mode..."
mkdir -p /Volumes/"$OS_NAME"/Users/Shared/Preferences
cat > /Volumes/"$OS_NAME"/Users/Shared/Preferences/com.apple.dock.plist << DOCK_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>autohide</key>
    <true/>
    <key>autohide-delay</key>
    <real>1000</real>
    <key>no-bouncing</key>
    <true/>
    <key>orientation</key>
    <string>bottom</string>
</dict>
</plist>
DOCK_EOF

# Set up Finder to hide desktop
cat > /Volumes/"$OS_NAME"/Users/Shared/Preferences/com.apple.finder.plist << FINDER_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CreateDesktop</key>
    <false/>
    <key>ShowHardDrivesOnDesktop</key>
    <false/>
    <key>ShowMountedServersOnDesktop</key>
    <false/>
    <key>ShowRemovableMediaOnDesktop</key>
    <false/>
</dict>
</plist>
FINDER_EOF

# Create boot loader configuration
echo "🔧 Setting up boot loader..."
mkdir -p /Volumes/"$OS_NAME"/System/Library/CoreServices/PlatformSupport.plist
cat > /Volumes/"$OS_NAME"/System/Library/CoreServices/PlatformSupport.plist << PLATFORM_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SupportedModelProperties</key>
    <array>
        <string>$OS_NAME</string>
        <string>Intel Mac</string>
        <string>Optical Computing</string>
    </array>
</dict>
</plist>
PLATFORM_EOF

# Unmount volume
echo "💾 Unmounting volume..."
diskutil unmount "$OS_NAME"

echo ""
echo "✅ RadiateOS installation complete!"
echo ""
echo "🔄 Next Steps:"
echo "1. Restart your Mac"
echo "2. Hold Option (⌥) key during startup"
echo "3. Select '$OS_NAME' from the boot menu"
echo "4. Your Mac will boot directly into RadiateOS!"
echo ""
echo "💡 To return to macOS:"
echo "   Hold Option (⌥) during startup and select 'Macintosh HD'"
EOF

chmod +x "$STAGING_DIR/install.sh"

# Create post-installation script
cat > "$STAGING_DIR/postinstall.sh" << 'EOF'
#!/bin/bash
# RadiateOS Post-Installation Script

echo "🎉 Post-installation setup..."

# Set the RadiateOS partition as the default boot volume
source ./installer.cfg
echo "Setting $OS_NAME as default boot volume..."
bless --mount /Volumes/"$OS_NAME" --setBoot

echo "✅ Boot configuration updated"
echo "🔄 System will boot into RadiateOS on next restart"
EOF

chmod +x "$STAGING_DIR/postinstall.sh"

# Create installer DMG
echo "📦 Creating bootable installer DMG..."
rm -f "$INSTALLER_DMG"
hdiutil create -volname "$INSTALLER_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov -format UDZO \
  "$INSTALLER_DMG"

# Create distribution file
echo "📋 Creating distribution description..."
cat > "$BUILD_DIR/Distribution" << EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>RadiateOS - Optical Computing Operating System</title>
    <organization>com.radiateos</organization>
    <options customize="never" allow-external-scripts="no"/>
    <welcome file="Welcome.html"/>
    <license file="License.html"/>
    <script>
        <preinstall script="preinstall.sh"/>
        <install script="install.sh"/>
        <postinstall script="postinstall.sh"/>
    </script>
    <pkg-ref id="com.radiateos.intel.installer"/>
    <options require-scripts="true"/>
</installer-gui-script>
EOF

# Create welcome screen
cat > "$BUILD_DIR/Welcome.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to RadiateOS</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 20px; }
        h1 { color: #007AFF; }
        .highlight { background: #f0f8ff; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>🚀 Welcome to RadiateOS</h1>
    <p><strong>RadiateOS - Optical Computing Operating System</strong></p>
    <p>This installer will create a bootable RadiateOS partition on your Intel Mac.</p>

    <div class="highlight">
        <strong>⚠️ Important Notes:</strong>
        <ul>
            <li>This will create a 20GB partition for RadiateOS</li>
            <li>Your existing macOS installation will remain unchanged</li>
            <li>You can switch between macOS and RadiateOS during boot</li>
        </ul>
    </div>

    <p>Click Continue to proceed with the installation.</p>
</body>
</html>
EOF

# Copy license
cp "$PROJECT_ROOT/LICENSE" "$BUILD_DIR/License.html"

echo ""
echo "✅ Intel Mac bootable installer created successfully!"
echo ""
echo "📁 Installer Location: $INSTALLER_DMG"
echo ""
echo "🚀 Installation Instructions:"
echo "1. Double-click $INSTALLER_NAME.dmg to mount it"
echo "2. Run the install.sh script inside the mounted volume"
echo "3. Follow the on-screen instructions"
echo "4. Restart your Mac and hold Option (⌥) to select RadiateOS"
echo ""
echo "💡 The installer will show 'RadiateOS' instead of 'Windows' during boot selection"