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
