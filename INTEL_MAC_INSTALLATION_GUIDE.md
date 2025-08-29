# RadiateOS Installation Guide for Intel Macs

## 🚨 Critical Fix for Blue Screen / "Windows" Branding Issue

If you're seeing a blue screen or "Windows" branding during installation, **delete any existing installer files** and follow this guide instead.

## Prerequisites

- **Intel-based Mac** (iMac, MacBook Pro, Mac Mini, Mac Pro with Intel processor)
- **macOS 12.0 or later**
- **8GB RAM minimum** (16GB recommended)
- **25GB free storage space**
- **Administrator privileges**

## Step 1: Build the Correct Installer

The issue you experienced was caused by using the VM installer instead of the native Intel Mac installer. Let's create the proper one:

```bash
# Navigate to your project directory
cd /Users/mostafanasr/Desktop/TheKernel

# Run the Intel Mac installer creator
./create_intel_bootable_installer.sh
```

This will create:
- `/build/installers/intel-pc/RadiateOS-Intel-Installer.dmg`
- Proper boot configuration with "RadiateOS" branding
- Native Intel Mac installation scripts

## Step 2: Prepare Your Mac

1. **Backup important data** (recommended but not required)
2. **Ensure sufficient storage** (25GB+ free space)
3. **Close all applications**
4. **Disable FileVault** if enabled (System Settings → Privacy & Security)

## Step 3: Run the Installer

1. **Mount the installer DMG**:
   ```bash
   # Double-click the DMG file or run:
   hdiutil attach build/installers/intel-pc/RadiateOS-Intel-Installer.dmg
   ```

2. **Open Terminal** and navigate to the mounted volume:
   ```bash
   cd /Volumes/RadiateOS-Intel-Installer
   ```

3. **Run the pre-installation check**:
   ```bash
   ./preinstall.sh
   ```

4. **Run the main installation**:
   ```bash
   sudo ./install.sh
   ```

## Step 4: Configure Boot Settings

After installation, set RadiateOS as the default boot option:

1. **Open System Settings** → **General** → **Startup Disk**
2. **Select "RadiateOS"** from the list
3. **Restart your Mac**

## Step 5: First Boot

1. **Your Mac will restart**
2. **You should see "RadiateOS" in the boot menu** (not "Windows")
3. **Select RadiateOS and press Enter**
4. **RadiateOS will boot automatically**

## Troubleshooting

### Still Seeing "Windows" Instead of "RadiateOS"

If you still see "Windows" during boot:

1. **Reset SMC** (System Management Controller):
   - Shut down your Mac
   - Press and hold **Shift + Control + Option + Power** for 10 seconds
   - Release all keys
   - Press Power to turn on

2. **Reset NVRAM/PRAM**:
   - Shut down your Mac
   - Press **Command + Option + P + R** immediately after turning on
   - Hold for 20 seconds, then release

3. **Re-run the installer** with the correct Intel version

### Blue Screen During Installation

If you get a blue screen:

1. **Force restart**: Hold Power button for 10 seconds
2. **Boot into Recovery Mode**: Hold **Command + R** during startup
3. **Open Disk Utility** and verify the RadiateOS partition exists
4. **Re-run the installer**

### RadiateOS Won't Boot

1. **Check partition integrity**:
   ```bash
   diskutil list
   diskutil verifyVolume /Volumes/RadiateOS
   ```

2. **Reinstall if necessary**:
   ```bash
   sudo diskutil eraseVolume APFS "RadiateOS" /dev/diskXsY
   # Then re-run the installer
   ```

## Switching Between macOS and RadiateOS

### From macOS to RadiateOS
- System Settings → General → Startup Disk → Select RadiateOS
- Restart

### From RadiateOS to macOS
- Apple menu → Restart
- Hold **Option (⌥)** during restart
- Select "Macintosh HD"

## Recovery Options

### Emergency Return to macOS
1. **Hold Option (⌥)** during startup
2. **Select your main macOS drive**
3. **Boot into safe mode** if needed: Hold **Shift** during startup

### Remove RadiateOS (if needed)
```bash
# Boot into macOS Recovery Mode
# Open Terminal from Utilities menu
diskutil list
diskutil eraseVolume APFS "RadiateOS" /dev/diskXsY
```

## Performance Tips for Intel Macs

- **Allocate maximum RAM** in virtualization settings
- **Enable hardware acceleration**
- **Use SSD storage** for best performance
- **Close background applications** in macOS

## What You Should See

After successful installation:
- ✅ **Boot menu shows "RadiateOS"** (not "Windows")
- ✅ **Clean boot without blue screen**
- ✅ **RadiateOS launches automatically**
- ✅ **Full desktop environment loads**
- ✅ **All applications work correctly**

## Support

If you continue to experience issues:
1. Check the installer logs in `/var/log/radiateos/`
2. Verify your Mac model supports the installation
3. Ensure you have the latest macOS updates
4. Try installing on a different Intel Mac to isolate hardware issues

---

**This updated installer specifically addresses the blue screen and "Windows" branding issues you experienced. The new version properly configures the boot loader for Intel Macs.**