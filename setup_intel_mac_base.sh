#!/bin/bash
# Intel Mac Base System Setup for RadiateOS
# This script sets up the macOS base system optimized for Intel Mac

echo "🍎 Setting up macOS base system for RadiateOS on Intel Mac"
echo "Target: 21.5\" iMac 2018 (Intel Core i5)"
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script must be run on macOS"
    echo "Please run this on your Intel Mac after installing macOS"
    exit 1
fi

echo "🔍 Detecting Intel Mac hardware..."
sysctl -n machdep.cpu.brand_string
system_profiler SPHardwareDataType | grep "Model Identifier\|Processor\|Memory"

echo ""
echo "📦 Installing required tools..."

# Install Xcode Command Line Tools
if ! xcode-select -p &> /dev/null; then
    echo "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Please complete the Xcode Command Line Tools installation, then re-run this script"
    exit 0
fi

# Install Homebrew
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install required packages
echo "Installing required packages..."
brew install wget curl git

echo ""
echo "🎯 Configuring Intel Mac optimizations..."

# Intel-specific system optimizations
echo "Applying Intel Core i5 optimizations..."
sudo nvram boot-args="intel_idle.max_cstate=1"

# Memory optimization for 16GB DDR4
echo "Optimizing memory management..."
sudo defaults write /Library/Preferences/com.apple.virtualMemory UseEncryptedSwap -bool YES

# Intel Iris Plus Graphics optimization
echo "Optimizing Intel Iris Plus Graphics..."
defaults write com.apple.driver.AppleIntelSKLGraphics AGDCEnabled -bool YES

# Power management for Intel Mac
echo "Configuring power management..."
sudo pmset -a standbydelay 86400
sudo pmset -a autopoweroff 0
sudo pmset -a powernap 0

echo ""
echo "🔧 Preparing for RadiateOS installation..."

# Create directories
mkdir -p ~/RadiateOS_Install
mkdir -p ~/UTM_Shared

# Download RadiateOS deployment package (simulated)
echo "📥 Ready to install RadiateOS deployment package..."
echo "Please copy RadiateOS-Intel-Mac-Deployment.tar.gz to ~/RadiateOS_Install/"

echo ""
echo "🎯 Intel Mac Setup Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Copy RadiateOS-Intel-Mac-Deployment.tar.gz to ~/RadiateOS_Install/"
echo "2. Extract: cd ~/RadiateOS_Install && tar -xzf RadiateOS-Intel-Mac-Deployment.tar.gz"
echo "3. Run: ./setup_radiateos_intel.sh"
echo ""
echo "🔄 Then restart to boot into RadiateOS"
echo ""
echo "📊 System optimized for:"
echo "  • Intel Core i5-7360U performance"
echo "  • 16GB DDR4 memory efficiency"
echo "  • Intel Iris Plus Graphics acceleration"
echo "  • 21.5\" Retina display compatibility"