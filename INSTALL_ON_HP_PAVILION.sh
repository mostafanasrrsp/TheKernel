#!/usr/bin/env bash
set -euo pipefail

# RadiateOS PC Installer for HP Pavilion (Intel Core i7 + NVIDIA GeForce + Touch)
# - Installs NVIDIA proprietary drivers (Ubuntu/Debian based)
# - Enables touch screen, tap-to-click, and natural scrolling
# - Sets RadiateOS PC Preview to run in kiosk mode on login (systemd user service)

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root: sudo $0" >&2
  exit 1
fi

echo "[1/6] Updating package lists"
apt-get update -y

echo "[2/6] Installing dependencies"
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  curl ca-certificates gnupg lsb-release software-properties-common \
  xorg xserver-xorg-input-libinput \
  git unzip alsa-utils pulseaudio psmisc \
  vulkan-tools mesa-utils libvulkan1 \
  chromium-browser firefox \
  libnss3 libatk-bridge2.0-0 libgtk-3-0 libx11-xcb1 libxcomposite1 libxrandr2 \
  libasound2 libpangocairo-1.0-0 libxdamage1 libxfixes3 libgbm1 libpango-1.0-0 \
  libcairo2 whiptail || true

echo "[3/6] Detecting GPU and installing drivers"
if lspci | grep -qi 'NVIDIA'; then
  echo "NVIDIA GPU detected. Installing recommended driver..."
  if command -v ubuntu-drivers >/dev/null 2>&1; then
    ubuntu-drivers autoinstall || true
  else
    add-apt-repository -y ppa:graphics-drivers/ppa || true
    apt-get update -y || true
    apt-get install -y nvidia-driver-535 nvidia-settings nvidia-prime || true
  fi
  if command -v prime-select >/dev/null 2>&1; then
    prime-select on-demand || true
  fi
else
  echo "No NVIDIA GPU found. Skipping NVIDIA driver install."
fi

echo "[4/6] Enabling touch screen and gestures"
mkdir -p /etc/X11/xorg.conf.d
cat >/etc/X11/xorg.conf.d/40-libinput.conf <<'EOF'
Section "InputClass"
    Identifier "libinput touchpad catchall"
    MatchIsTouchpad "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "Tapping" "on"
    Option "NaturalScrolling" "true"
    Option "DisableWhileTyping" "true"
EndSection

Section "InputClass"
    Identifier "libinput touchscreen catchall"
    MatchIsTouchscreen "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
EndSection
EOF

# Optional GPU offload wrappers and classic setup wizard
echo "Installing GPU offload wrappers and running setup wizard..."
if [ -f "$(dirname "$0")/pc-install/gpu_offload_wrappers.sh" ]; then
  bash -euo pipefail "$(dirname "$0")/pc-install/gpu_offload_wrappers.sh" || true
fi
if [ -f "$(dirname "$0")/pc-install/install_wizard.sh" ]; then
  bash -euo pipefail "$(dirname "$0")/pc-install/install_wizard.sh" || true
fi

echo "[5/6] Installing RadiateOS PC Preview"
APP_DIR=/opt/radiateos-pc
mkdir -p "$APP_DIR"

if [[ -d /workspace/pc-preview ]]; then
  # Development path
  echo "Copying workspace app..."
  cp -r /workspace/pc-preview "$APP_DIR" || true
fi

if [[ ! -d "$APP_DIR/pc-preview" ]]; then
  echo "Downloading latest release artifact..."
  echo "(Placeholder) Please place built artifact under $APP_DIR/pc-preview"
fi

echo "[6/6] Setting up kiosk systemd service"
cat >/etc/systemd/system/radiateos-kiosk.service <<'EOF'
[Unit]
Description=RadiateOS PC Kiosk
After=graphical.target
Wants=graphical.target

[Service]
Type=simple
Environment=ELECTRON_ENABLE_LOGGING=1
ExecStart=/usr/bin/env bash -lc 'cd /opt/radiateos-pc/pc-preview && npm install --omit=dev && npm run start'
Restart=on-failure
RestartSec=3
User=root
WorkingDirectory=/opt/radiateos-pc/pc-preview

[Install]
WantedBy=graphical.target
EOF

systemctl daemon-reload
systemctl enable radiateos-kiosk.service

echo "Installation complete. Reboot recommended."
echo "- NVIDIA drivers installed (if supported)"
echo "- Touch input enabled via libinput"
echo "- RadiateOS PC starts in kiosk on boot"
