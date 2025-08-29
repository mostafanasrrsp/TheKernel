# RadiateOS Preview for PC (Windows/Linux)

This is a non-native Electron preview that showcases the RadiateOS UI shell. It does not include macOS-only internals, but provides a way to evaluate on standard PCs.

## Quick Start (Windows)

1. Install Node.js 20 LTS.
2. Open PowerShell in this folder.
3. Run:
```
npm install
npm start
```
4. To make an installer:
```
npm run build:win
```

## Quick Start (Linux)

```
npm install
npm start
# or build
npm run build:linux
```

## Notes
- This preview uses standard mouse/keyboard input. Touch works if the OS provides touch events.
- Trackpad click issues on your HP should not affect the app (mouse works).
- NVIDIA GPUs are supported via the OS/driver; the app itself is GPU-agnostic.

## Full RadiateOS (macOS VM)
If you need the authentic macOS build, use the scripts in `RadiateOS/scripts/create_vm_image.sh` to produce a UTM/QEMU config, then install macOS in a VM and run `build/vm/install_radiateos.sh` inside the VM.