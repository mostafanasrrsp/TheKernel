# RadiateOS PC Install (HP Pavilion Intel + NVIDIA + Touch)

## Requirements
- HP Pavilion with Intel Core i7 and NVIDIA GeForce GPU
- Ubuntu 22.04+ or Debian 12+ (recommended)
- Internet connection
- sudo privileges

## Quick Install
```bash
cd /workspace
sudo chmod +x INSTALL_ON_HP_PAVILION.sh
sudo ./INSTALL_ON_HP_PAVILION.sh
```
What this does:
- Installs NVIDIA proprietary drivers (if supported)
- Enables touch/gesture support (libinput)
- Installs RadiateOS PC Preview to `/opt/radiateos-pc/pc-preview`
- Creates `radiateos-kiosk.service` to auto-start at boot

Reboot when done.

## Build Preview Locally (optional)
```bash
cd /workspace/pc-build
chmod +x build_radiateos_pc.sh
./build_radiateos_pc.sh
# Extract artifacts from Docker image (see output instructions)
```

Copy your built artifact to `/opt/radiateos-pc/pc-preview` or replace the `ExecStart` in the systemd unit to point to your packaged binary.

## NVIDIA Notes
- Verify GPU: `nvidia-smi`
- If laptop has hybrid graphics, consider: `sudo apt install nvidia-prime` and set performance mode.

## Touchscreen
- Configured via `/etc/X11/xorg.conf.d/40-libinput.conf`
- Adjust options (tap-to-click, natural scrolling) as desired.

## Disable Kiosk
```bash
sudo systemctl disable --now radiateos-kiosk.service
```

## Logs
```bash
journalctl -u radiateos-kiosk.service -f
```