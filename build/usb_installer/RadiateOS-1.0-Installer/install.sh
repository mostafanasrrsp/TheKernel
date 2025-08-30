#!/bin/bash
# RadiateOS Installation Script

set -e

echo "🚀 Installing RadiateOS..."

# Detect target system
if [ -d "/Applications" ]; then
    # macOS system
    echo "Installing on macOS..."
    sudo cp -R Applications/RadiateOS.app /Applications/ 2>/dev/null || true
elif [ -d "/usr/local/bin" ]; then
    # Linux/Unix system
    echo "Installing on Linux/Unix..."
    sudo cp System/RadiateOS /usr/local/bin/ 2>/dev/null || true
    sudo chmod +x /usr/local/bin/RadiateOS
fi

# Copy system files
sudo mkdir -p /opt/radiateos
sudo cp -r System/* /opt/radiateos/ 2>/dev/null || true

echo "✅ RadiateOS installation complete!"
echo "Run 'radiateos' to start the system"
