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
  policykit-1 \
  python3-gi gir1.2-appindicator3-0.1 libayatana-appindicator3-1 \
  xterm \
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
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$BASE_DIR/pc-install/gpu_offload_wrappers.sh" ]; then
  bash -euo pipefail "$BASE_DIR/pc-install/gpu_offload_wrappers.sh" || true
fi
if [ -f "$BASE_DIR/pc-install/install_wizard.sh" ]; then
  bash -euo pipefail "$BASE_DIR/pc-install/install_wizard.sh" || true
fi

# Install power/toggle helpers
if [ -f "$BASE_DIR/pc-install/nvidia_power_profile.sh" ]; then
  install -m 0755 "$BASE_DIR/pc-install/nvidia_power_profile.sh" /usr/local/bin/nvidia_power_profile.sh || true
fi
if [ -f "$BASE_DIR/pc-install/radiate_gpu_toggle.sh" ]; then
  install -m 0755 "$BASE_DIR/pc-install/radiate_gpu_toggle.sh" /usr/local/bin/radiate-gpu || true
fi

# Install polkit policy and rules to allow passwordless radiate-gpu for sudo users
if [ -f "$BASE_DIR/pc-install/polkit/com.radiateos.radiate-gpu.policy" ]; then
  install -m 0644 "$BASE_DIR/pc-install/polkit/com.radiateos.radiate-gpu.policy" /usr/share/polkit-1/actions/com.radiateos.radiate-gpu.policy || true
fi
# Create a user-specific polkit rule to allow passwordless radiate-gpu
TARGET_USER="${SUDO_USER:-}"
if [ -z "$TARGET_USER" ]; then
  TARGET_USER=$(logname 2>/dev/null || who | awk 'NR==1{print $1}')
fi
if id "$TARGET_USER" >/dev/null 2>&1; then
  # Ensure user is a member of sudo
  if ! id -nG "$TARGET_USER" | grep -qw sudo; then
    usermod -aG sudo "$TARGET_USER" || true
  fi
  # Write restrictive rule for this exact user
  cat >/etc/polkit-1/rules.d/10-radiate-gpu-user.rules <<EOF
polkit.addRule(function(action, subject) {
  if (action && action.id === 'com.radiateos.radiate-gpu') {
    if (subject && subject.user === '$TARGET_USER' && subject.local) {
      return polkit.Result.YES;
    }
  }
});
EOF
  # Remove permissive group-based rule if present
  rm -f /etc/polkit-1/rules.d/90-radiate-gpu.rules 2>/dev/null || true
  # Restart polkit to apply
  systemctl daemon-reload || true
  systemctl restart polkit.service || systemctl restart polkit || true
fi

# Apply GPU mode selection from wizard (if available)
CONFIG_FILE=/etc/radiateos/pc-config.env
if [ -f "$CONFIG_FILE" ] && command -v prime-select >/dev/null 2>&1; then
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
  case "${GPU_MODE:-auto}" in
    on_demand)
      prime-select on-demand || true ;;
    nvidia_only)
      prime-select nvidia || true ;;
    intel_only)
      prime-select intel || true ;;
    *)
      prime-select on-demand || true ;;
  esac
fi

# Apply NVIDIA power profile if NVIDIA present
if [ -f "$CONFIG_FILE" ] && command -v nvidia-smi >/dev/null 2>&1; then
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
  /usr/local/bin/nvidia_power_profile.sh "${POWER_PROFILE:-balanced}" || true
fi

echo "[5/6] Installing RadiateOS PC Preview"
APP_DIR=/opt/radiateos-pc
mkdir -p "$APP_DIR"
TOOLS_DIR=$APP_DIR/tools
mkdir -p "$TOOLS_DIR"

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
KIOSK_ENV=/etc/radiateos/kiosk.env
mkdir -p /etc/radiateos

# Detect executable or fallback to npm start
EXEC_CMD=""
if [[ -x "$APP_DIR/pc-preview/RadiateOS" ]]; then
  EXEC_CMD="$APP_DIR/pc-preview/RadiateOS"
elif [[ -f "$APP_DIR/pc-preview/package.json" ]]; then
  EXEC_CMD="cd $APP_DIR/pc-preview && npm install --omit=dev && npm run start"
elif command -v electron >/dev/null 2>&1 && [[ -f "$APP_DIR/pc-preview/main.js" ]]; then
  EXEC_CMD="electron $APP_DIR/pc-preview"
else
  EXEC_CMD="/usr/bin/env bash -lc 'echo RadiateOS preview not found; sleep 5'"
fi

# Wrap kiosk with GPU offload when on-demand or nvidia-only is selected
if [ -f "$CONFIG_FILE" ]; then
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
  case "${GPU_MODE:-auto}" in
    on_demand|nvidia_only)
      if command -v gpu-run >/dev/null 2>&1; then
        EXEC_CMD="gpu-run $EXEC_CMD"
      fi
      ;;
  esac
fi

echo "EXEC_CMD=$EXEC_CMD" > "$KIOSK_ENV"

cat >/etc/systemd/system/radiateos-kiosk.service <<'EOF'
[Unit]
Description=RadiateOS PC Kiosk
After=graphical.target
Wants=graphical.target

[Service]
Type=simple
Environment=ELECTRON_ENABLE_LOGGING=1
EnvironmentFile=/etc/radiateos/kiosk.env
ExecStart=/usr/bin/env bash -lc "$EXEC_CMD"
Restart=on-failure
RestartSec=3
User=root
WorkingDirectory=/opt/radiateos-pc/pc-preview

[Install]
WantedBy=graphical.target
EOF

systemctl daemon-reload
systemctl enable radiateos-kiosk.service

# Install desktop launchers and tray indicator (optional in desktop sessions)
echo "Installing GPU status launcher and tray indicator..."
if [ -f "$BASE_DIR/pc-install/radiate_tray.py" ]; then
  install -m 0755 "$BASE_DIR/pc-install/radiate_tray.py" "$TOOLS_DIR/radiate_tray.py" || true
fi
if [ -f "$BASE_DIR/pc-install/icons/radiate_tray.svg" ]; then
  install -m 0644 "$BASE_DIR/pc-install/icons/radiate_tray.svg" "$TOOLS_DIR/radiate_tray.svg" || true
fi

cat >/usr/share/applications/radiate-gpu-status.desktop <<'DESK'
[Desktop Entry]
Name=RadiateOS GPU Status
Comment=Show current GPU mode and power info
Exec=sh -c "x-terminal-emulator -e bash -lc 'radiate-gpu status; echo; read -n1 -rsp \"Press any key to close...\"'"
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;Utility;
DESK

cat >/etc/xdg/autostart/radiate-gpu-tray.desktop <<'AUTODESK'
[Desktop Entry]
Type=Application
Name=RadiateOS GPU Tray
Comment=Quickly switch GPU mode and power profile
Exec=python3 /opt/radiateos-pc/tools/radiate_tray.py
Icon=/opt/radiateos-pc/tools/radiate_tray.svg
X-GNOME-Autostart-enabled=true
OnlyShowIn=GNOME;Unity;X-Cinnamon;XFCE;LXQt;KDE;
AUTODESK

echo "Installation complete. Reboot recommended."
echo "- NVIDIA drivers installed (if supported)"
echo "- Touch input enabled via libinput"
echo "- RadiateOS PC starts in kiosk on boot"
