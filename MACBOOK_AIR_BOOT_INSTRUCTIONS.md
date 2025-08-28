# RadiateOS Boot Instructions for MacBook Air

## Quick Start Guide

### Prerequisites
- MacBook Air (M1/M2/M3 or Intel)
- 8GB free storage space
- UTM app installed (download from [mac.getutm.app](https://mac.getutm.app))

### Option 1: Virtual Machine Boot (Recommended - Safe)

1. **Download UTM** if not already installed
2. **Import RadiateOS VM**:
   - Open UTM
   - Click "+" → "Open" 
   - Navigate to `/Users/mostafanasr/Desktop/TheKernel/RadiateOS/build/vm/RadiateOS.utm`
   - Select and open

3. **Start RadiateOS**:
   - Click on RadiateOS VM in UTM
   - Press "Play" button
   - RadiateOS will boot automatically

### Option 2: Native Boot from DMG (Advanced)

⚠️ **WARNING**: This creates a separate boot volume. Your main macOS remains safe.

1. **Create Boot Volume**:
   ```bash
   # Attach DMG
   hdiutil attach /Users/mostafanasr/Desktop/TheKernel/RadiateOS/build/macos/RadiateOS.dmg
   
   # Create 20GB APFS volume for RadiateOS
   diskutil apfs addVolume disk1 APFS RadiateOS
   
   # Copy RadiateOS to new volume
   cp -R /Volumes/RadiateOS/RadiateOS.app /Volumes/RadiateOS/Applications/
   ```

2. **Set as Startup Disk**:
   - System Settings → General → Startup Disk
   - Select "RadiateOS" volume
   - Restart

3. **Boot into RadiateOS**:
   - MacBook will restart into RadiateOS
   - To return to macOS: Hold Option (⌥) during startup

### Option 3: Recovery Mode Installation (Expert)

1. **Restart into Recovery**:
   - Apple Silicon: Hold Power button until options appear
   - Intel: Hold Command (⌘) + R during restart

2. **Open Terminal** from Utilities menu

3. **Install RadiateOS**:
   ```bash
   # Mount main drive
   diskutil mount disk1s1
   
   # Copy RadiateOS
   cp -R /Volumes/Macintosh\ HD/Users/mostafanasr/Desktop/TheKernel/RadiateOS/RadiateOS.app /Applications/
   
   # Set as login item
   defaults write com.apple.loginitems AlwaysOpenAtLogin -array-add "/Applications/RadiateOS.app"
   ```

4. **Restart** - RadiateOS will launch automatically

## Installation Wizard

Once RadiateOS boots, the Setup Wizard will:
1. Display welcome screen with optical animation
2. Configure system preferences
3. Set up user account
4. Initialize optical computing subsystems
5. Launch desktop environment

## Switching Between macOS and RadiateOS

### From RadiateOS → macOS:
- Click Apple menu → Restart → Hold Option (⌥) → Select Macintosh HD

### From macOS → RadiateOS:
- UTM Method: Open UTM and start VM
- Native Boot: System Settings → Startup Disk → RadiateOS

## Troubleshooting

### RadiateOS Won't Boot:
- Ensure UTM has sufficient resources (4GB RAM minimum)
- For native boot, verify volume has 10GB+ free space
- Check Security & Privacy settings allow app from identified developers

### Black Screen on Boot:
- Wait 30 seconds (initial optical system initialization)
- Press any key to wake display
- Force quit: Command (⌘) + Option (⌥) + Esc

### Return to macOS Emergency:
- Hold Option (⌥) during startup
- Select Macintosh HD
- Boot into safe mode if needed: Hold Shift during startup

## Performance Tips for MacBook Air

- **M1/M2/M3**: Enable hardware acceleration in UTM settings
- **Intel**: Allocate 4GB+ RAM to VM, use 2 CPU cores
- **All models**: Close other apps for best performance

## Quick Commands

```bash
# Check if RadiateOS is installed
ls -la /Applications/RadiateOS.app

# Launch RadiateOS from Terminal
open /Applications/RadiateOS.app

# Remove RadiateOS (if needed)
sudo rm -rf /Applications/RadiateOS.app
```

---
**Support**: For issues, check `/Users/mostafanasr/Desktop/TheKernel/RadiateOS/BOOTABLE_SETUP.md` for detailed instructions.