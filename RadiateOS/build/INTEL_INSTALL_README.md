# RadiateOS Intel Mac Installer

## Quick Installation

1. Extract the tar.gz file:
   ```bash
   tar -xzf RadiateOS-Intel-Installer.tar.gz
   cd intel_installer
   ```

2. Run the installation script:
   ```bash
   chmod +x install_intel.sh
   sudo ./install_intel.sh
   ```

3. Restart your Mac - RadiateOS will boot automatically!

## EFI Boot (Advanced)

For direct EFI booting:

1. Mount EFI partition:
   ```bash
   diskutil mount disk0s1
   ```

2. Copy EFI files:
   ```bash
   sudo cp -R EFI/* /Volumes/EFI/
   ```

3. Set boot options:
   ```bash
   sudo bless --mount /Volumes/Macintosh\ HD --setBoot
   ```

## Troubleshooting

- If you see Windows branding: Boot into Recovery Mode and run `nvram -c`
- If BSOD appears: Disable recovery mode with `sudo nvram "recovery-boot-mode=unused"`
- For clean install: Delete VM and start over with this installer

## Files Included

- `RadiateOS.app` - Main application
- `EFI/` - EFI boot configuration
- `install_intel.sh` - Installation script
- Configuration files for Intel Mac compatibility
