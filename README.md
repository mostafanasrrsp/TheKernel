# TheKernel

RadiateOS components and tooling.

## PC (HP Pavilion) Quick Start

- Recommended: Ubuntu 22.04+ (hybrid NVIDIA compatible)
- One‑liner install on Ubuntu/Debian:

```bash
curl -fsSL https://raw.githubusercontent.com/mostafanasrrsp/TheKernel/main/pc-install/quick_install.sh | bash
```

The installer auto‑detects NVIDIA, enables hybrid on‑demand mode, configures touch gestures, installs GPU wrappers, and offers a retro Windows‑style setup wizard.

To use the dGPU only for heavy apps: launch via `gpu-run <cmd>`, `chromium-gpu`, or `firefox-gpu`.

Ventoy USB guide and theme are in `usb/` (see `usb/VENTOY_USB_GUIDE.md`).
