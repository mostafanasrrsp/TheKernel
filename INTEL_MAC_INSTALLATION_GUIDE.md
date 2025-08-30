# RadiateOS Intel Mac Installation Guide

## 🚨 Critical Fix for BSOD and Windows Branding Issues

If you're experiencing:
- Blue Screen of Death (BSOD)
- System showing "Windows" instead of "RadiateOS"
- Boot failures on Intel Macs

Follow this guide to fix your installation.

## Prerequisites

- Intel Mac (any model)
- UTM app installed ([mac.getutm.app](https://mac.getutm.app))
- macOS Monterey or Ventura installer
- 8GB+ free disk space

## Step 1: Clean Previous Installation

If you have a broken installation:

```bash
# Remove old VM if it exists
rm -rf ~/Library/Containers/com.utmapp.UTM/Data/Documents/RadiateOS.utm

# Clear any cached configurations
defaults delete com.utmapp.UTM 2>/dev/null || true
```

## Step 2: Apply Intel Mac Fixes

Run the fix script:

```bash
cd /Users/mostafanasr/Desktop/TheKernel
./fix_intel_boot_branding.sh
```

This creates:
- Intel-optimized UTM configuration
- Proper macOS branding
- BSOD prevention settings

## Step 3: Create Fresh VM in UTM

1. **Open UTM**
2. **Create New VM:**
   - Click "+" → "Create a New Virtual Machine"
   - Choose "Emulate" (for Intel compatibility)
   - Select "macOS 12+" as operating system
3. **Import Configuration:**
   - Instead of using UTM's wizard, click "Browse" in the bottom right
   - Navigate to: `RadiateOS/build/vm/RadiateOS.utm/`
   - Select the folder and click "Open"

## Step 4: Install macOS Base System

1. **Start the VM**
2. **Boot from macOS Installer:**
   - When prompted, select "Install macOS Monterey" (or Ventura)
   - Complete the installation wizard
   - Create a user account (this will be hidden later)
3. **Complete Setup:**
   - Skip iCloud and other services for now
   - Don't install any additional software

## Step 5: Install RadiateOS

1. **Copy Installation Files:**
   ```bash
   # In the host macOS, create a shared folder
   mkdir -p ~/UTM_Shared
   cp RadiateOS/build/vm/install_radiateos_intel.sh ~/UTM_Shared/
   cp RadiateOS/build/vm/kiosk/com.radiateos.kiosk.plist ~/UTM_Shared/
   ```

2. **Configure VM Sharing:**
   - In UTM: VM Settings → Drives → Add → Directory
   - Select `~/UTM_Shared` as shared directory
   - Mount point: `/Volumes/Shared`

3. **Run Installation Script:**
   ```bash
   # Inside the VM terminal
   cd /Volumes/Shared
   chmod +x install_radiateos_intel.sh
   sudo ./install_radiateos_intel.sh
   ```

## Step 6: Configure Kiosk Mode

The installation script automatically:
- ✅ Hides macOS Dock and Menu Bar
- ✅ Sets RadiateOS as the primary interface
- ✅ Disables desktop icons
- ✅ Creates Intel-compatible launch agents
- ✅ Prevents Windows branding
- ✅ Disables BSOD recovery options

## Step 7: Final Boot Test

1. **Restart the VM:**
   ```bash
   sudo reboot
   ```

2. **Verify RadiateOS:**
   - Should boot directly into RadiateOS
   - No Windows branding visible
   - No BSOD or repair screens
   - Clean RadiateOS interface

## Troubleshooting

### Still Seeing Windows Branding?

```bash
# Inside VM, force branding update
sudo defaults write /Library/Preferences/com.apple.loginwindow DesktopPicture ""
sudo defaults write com.apple.desktop BackgroundColor -array 0 0 0
sudo killall loginwindow
```

### BSOD Persists?

```bash
# Disable recovery mode
sudo nvram "recovery-boot-mode=unused"
sudo nvram "boot-args=-v"
```

### VM Won't Start?

- Ensure hardware acceleration is enabled in UTM
- Allocate at least 4GB RAM to VM
- Use 2 CPU cores minimum
- Check that shared networking is enabled

## Performance Optimization for Intel Macs

### VM Settings:
- **Memory:** 6-8GB (more is better)
- **CPU Cores:** 2-4 cores
- **Display:** Retina resolution
- **Storage:** 64GB minimum

### macOS Settings (inside VM):
```bash
# Optimize for performance
sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool true
defaults write com.apple.finder DisableAllAnimations -bool true
```

## Alternative: Native Boot (Advanced)

⚠️ **WARNING**: This modifies your host macOS. Back up first!

1. **Create Boot Volume:**
   ```bash
   # Create APFS volume for RadiateOS
   diskutil apfs addVolume disk1 APFS RadiateOS 20g
   ```

2. **Install RadiateOS:**
   ```bash
   # Copy app to new volume
   cp -R RadiateOS/build/macos/RadiateOS.app /Volumes/RadiateOS/Applications/
   ```

3. **Set Startup Disk:**
   - System Settings → General → Startup Disk
   - Select "RadiateOS" volume
   - Restart and hold Option (⌥) to select

## Recovery Options

If everything fails:

1. **Reset VM:**
   ```bash
   # Delete and recreate VM
   rm -rf ~/Library/Containers/com.utmapp.UTM/Data/Documents/RadiateOS.utm
   ./fix_intel_boot_branding.sh
   ```

2. **Fresh macOS Install:**
   - Delete VM completely
   - Start over with fresh macOS installation
   - Re-run the Intel fix script

## Success Indicators

✅ **RadiateOS boots cleanly**
✅ **No Windows branding visible**
✅ **No BSOD or repair screens**
✅ **Desktop environment loads properly**
✅ **All applications accessible**

---

**Need Help?** Check the console logs in the VM for errors, or verify that all configuration files were created correctly by the fix script.