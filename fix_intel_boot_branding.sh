#!/bin/bash

# RadiateOS Intel Mac Boot Branding Fix
# Fixes the "Windows" branding issue during boot

set -euo pipefail

echo "🔧 Fixing RadiateOS boot branding for Intel Mac..."

# Check if running on Intel Mac
if [[ "$(uname -m)" != "x86_64" ]]; then
    echo "❌ This script is only for Intel Macs"
    exit 1
fi

# Check if RadiateOS is installed
if [[ ! -d "/Volumes/RadiateOS" ]] && [[ ! -d "/Applications/RadiateOS.app" ]]; then
    echo "❌ RadiateOS not found. Please install RadiateOS first."
    exit 1
fi

echo "✅ Intel Mac detected"
echo "✅ RadiateOS installation found"

# Fix SystemVersion.plist
echo "📝 Updating system version information..."
if [[ -d "/Volumes/RadiateOS" ]]; then
    TARGET_DIR="/Volumes/RadiateOS"
else
    TARGET_DIR="/"
fi

sudo mkdir -p "$TARGET_DIR/System/Library/CoreServices"

sudo tee "$TARGET_DIR/System/Library/CoreServices/SystemVersion.plist" > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ProductBuildVersion</key>
    <string>21G1974</string>
    <key>ProductCopyright</key>
    <string>2024 RadiateOS Project. All rights reserved.</string>
    <key>ProductName</key>
    <string>RadiateOS</string>
    <key>ProductUserVisibleVersion</key>
    <string>1.0</string>
    <key>ProductVersion</key>
    <string>1.0</string>
    <key>iOSSupportVersion</key>
    <string>15.0</string>
</dict>
</plist>
EOF

# Create PlatformSupport.plist
echo "🔧 Creating platform support configuration..."
sudo tee "$TARGET_DIR/System/Library/CoreServices/PlatformSupport.plist" > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SupportedModelProperties</key>
    <array>
        <string>RadiateOS</string>
        <string>Intel Mac</string>
        <string>Optical Computing</string>
        <string>x86_64</string>
    </array>
</dict>
</plist>
EOF

# Fix EFI boot configuration
echo "💾 Updating EFI boot configuration..."
sudo mkdir -p "$TARGET_DIR/System/Library/CoreServices/boot.efi"
sudo tee "$TARGET_DIR/System/Library/CoreServices/boot.efi/efi-boot-config.plist" > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BootTitle</key>
    <string>RadiateOS - Optical Computing OS</string>
    <key>BootLoader</key>
    <string>RadiateOS Boot Manager</string>
    <key>KernelFlags</key>
    <string>-v</string>
    <key>ProductName</key>
    <string>RadiateOS</string>
    <key>ProductVersion</key>
    <string>1.0</string>
</dict>
</plist>
EOF

# Update NVRAM boot arguments
echo "⚙️  Updating NVRAM boot arguments..."
sudo nvram "boot-args=-v"
sudo nvram "SystemAudioVolume=%00"
sudo nvram "radiateos-boot-title=RadiateOS - Optical Computing OS"

# Fix bless configuration
echo "🙏 Updating bless configuration..."
if [[ -d "/Volumes/RadiateOS" ]]; then
    sudo bless --mount /Volumes/RadiateOS --setBoot --nextonly
fi

# Create RadiateOS boot preference
echo "🎯 Creating boot preference..."
sudo tee "/Library/Preferences/SystemConfiguration/com.apple.Boot.plist" > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Kernel Flags</key>
    <string></string>
    <key>Boot Graphics</key>
    <true/>
    <key>Quiet Boot</key>
    <false/>
    <key>Timeout</key>
    <integer>5</integer>
    <key>Default Partition</key>
    <string>RadiateOS</string>
</dict>
</plist>
EOF

# Reset EFI firmware variables
echo "🔄 Resetting EFI firmware variables..."
sudo bless --reset

echo ""
echo "✅ Boot branding fix completed!"
echo ""
echo "🔄 Next Steps:"
echo "1. Restart your Mac"
echo "2. You should now see 'RadiateOS' instead of 'Windows' in the boot menu"
echo "3. Select RadiateOS to boot"
echo ""
echo "💡 If you still see 'Windows', try:"
echo "   - Reset SMC: Shift + Control + Option + Power (10 seconds)"
echo "   - Reset NVRAM: Command + Option + P + R (20 seconds)"
echo "   - Run this script again after booting into macOS Recovery"