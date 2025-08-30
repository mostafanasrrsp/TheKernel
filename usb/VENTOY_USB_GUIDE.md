RadiateOS 1.0 – Ventoy USB Guide (HP Pavilion, NVIDIA Hybrid)
============================================================

Goals
- One USB that boots Ubuntu 22.04 (for compatibility) and carries RadiateOS tools.
- Custom menu branding (RadiateOS 1.0), not “Windows”.
- GPU-friendly defaults for old hybrid NVIDIA laptops (use offload for selected apps).

What You Need
- A USB drive (16 GB+ recommended).
- Ventoy (https://www.ventoy.net) installed on macOS or Linux.
- Ubuntu 22.04.4 LTS ISO.
- This repo (for the installer + tools).

1) Install Ventoy on the USB
- macOS (Homebrew):
  - Install: brew install ventoy
  - Find disk: diskutil list   → identify your USB, e.g. /dev/disk4
  - Unmount: diskutil unmountDisk /dev/disk4
  - Install Ventoy: sudo ventoy -I /dev/disk4
    WARNING: This erases the USB.

- Linux:
  - Download and extract Ventoy from official site.
  - Find disk: lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL
  - Install: sudo ./Ventoy2Disk.sh -i /dev/sdX

2) Rename the USB and Prepare Partitions
- Ventoy creates two partitions: the first (exFAT) holds ISOs; second is Ventoy metadata.
- Label the first partition to be recognizable as RadiateOS 1.0:
  - macOS: diskutil rename /Volumes/VENTOY RadiateOS1_0
  - Linux: sudo fatlabel /dev/sdX1 RadiateOS1_0  (or use gparted)

3) Copy ISOs and Tools
- Copy Ubuntu 22.04 ISO to the USB first partition (now mounted as RadiateOS1_0):
  - ubuntu-22.04.4-desktop-amd64.iso
- Optionally add other ISOs too; Ventoy will list them in the menu.
- Create a tools folder on the USB and copy this repo or a subset:
  - RadiateOS-Tools/
    - TheKernel/ (this repo) or just INSTALL_ON_HP_PAVILION.sh and pc-install/

4) Add Ventoy Branding and Menu Customization
- Create a folder: RadiateOS-Tools/ventoy
- Copy the ventoy.json from this repo’s usb/ventoy/ventoy.json into RadiateOS-Tools/ventoy
- The file customizes the title, menu display name, and theme colors.
- Ventoy searches for ventoy.json on the first partition in /ventoy/ or /EFI/ventoy/. To be explicit:
 - Create USB:/ventoy/ and place ventoy.json there.

5) Add a Background Image (optional but recommended)
- Create USB:/ventoy/theme/
- Copy a wallpaper image to USB:/ventoy/theme/background.png (1920x1080 works well)
- Copy this repo’s usb/ventoy/theme/theme.txt to USB:/ventoy/theme/theme.txt
- ventoy.json already points to /ventoy/theme/theme.txt, which references background.png.

6) Boot the HP Pavilion
- Enter BIOS/UEFI setup, enable UEFI boot, and set USB first.
- Secure Boot: keep ON initially; if you hit a black screen, temporarily disable, install NVIDIA drivers, then re-enable.
- Select “Ubuntu 22.04” in the Ventoy menu.

7) Install Ubuntu and Run RadiateOS Installer
- Install Ubuntu normally.
- After first boot, plug the RadiateOS USB and open the tools folder.
- Run installer (root):
  - sudo bash INSTALL_ON_HP_PAVILION.sh
- Choose On-Demand GPU mode in the wizard to use dGPU for physics/3D/browsing only.

8) GPU-Acceleration for Physics/3D/Browsing Only
- The installer sets NVIDIA PRIME On-Demand on hybrid systems.
- Use wrappers to launch apps on the GPU:
  - gpu-run <command>
  - chromium-gpu, firefox-gpu
- This keeps the desktop on iGPU while offloading heavy tasks to the dGPU, reducing heat.

9) Make It Look Like RadiateOS (Not Windows)
- Volume label: RadiateOS1_0 (step 2).
- Ventoy menu title: “RadiateOS 1.0 Boot Menu” (ventoy.json).
- You can add a background image to the Ventoy theme (see ventoy docs). Place images under /ventoy/theme/ and reference in ventoy.json.

10) Troubleshooting
- Black screen on first boot: press e in GRUB, append nomodeset to linux line, boot; install NVIDIA, then remove nomodeset.
- NVIDIA power/heat: use balanced or throttled profile in wizard; you can adjust later by re-running /etc/radiateos/pc-config.env with nvidia-smi where supported.

11) Optional: Multi-boot and Persistence
- Ventoy supports multiple ISOs. For Ubuntu persistence, follow Ventoy’s persistence plugin guide.

That’s it. Your USB now boots Ubuntu with RadiateOS tooling and shows RadiateOS 1.0 branding.
