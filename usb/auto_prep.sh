#!/usr/bin/env bash
set -euo pipefail

# RadiateOS 1.0 – Auto USB Prep (Ventoy + Ubuntu ISO + Branding)
# Linux-only script. Requires sudo. ERases the selected USB device.

UBUNTU_ISO_URL=${UBUNTU_ISO_URL:-https://releases.ubuntu.com/22.04.4/ubuntu-22.04.4-desktop-amd64.iso}
MNT=${MNT:-/mnt/ventoy}
LABEL=${LABEL:-RadiateOS1_0}
THEME_JSON_URL=${THEME_JSON_URL:-https://raw.githubusercontent.com/mostafanasrrsp/TheKernel/v1.0.1/usb/ventoy/ventoy.json}
THEME_TXT_URL=${THEME_TXT_URL:-https://raw.githubusercontent.com/mostafanasrrsp/TheKernel/v1.0.1/usb/ventoy/theme/theme.txt}

need_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Missing: $1" >&2; exit 1; }; }

echo "RadiateOS Auto USB Prep — Linux"
if [[ $(id -u) -ne 0 ]]; then
  echo "Requesting sudo privileges..."
  sudo -v
fi

PKGS=(curl unzip tar)
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${PKGS[@]}" exfatprogs dosfstools || true
fi

need_cmd curl
need_cmd lsblk

echo "\nDetecting removable USB devices..."
lsblk -d -o NAME,RM,SIZE,MODEL,TRAN | sed '1 s/^/NAME   RM   SIZE   MODEL                TRAN\n/'
echo "\nEnter target device (e.g., sdb). This will be ERASED:"
read -r DEVNAME
[[ -n "$DEVNAME" ]] || { echo "No device specified" >&2; exit 1; }
DEV="/dev/${DEVNAME}"
[[ -b "$DEV" ]] || { echo "Device not found: $DEV" >&2; exit 1; }

echo "\nType ERASE to confirm wiping $DEV:"
read -r CONF
[[ "$CONF" == "ERASE" ]] || { echo "Aborted."; exit 1; }

echo "\nFetching latest Ventoy release..."
VREL=$(curl -fsSL https://api.github.com/repos/ventoy/Ventoy/releases/latest | sed -n 's/.*"tag_name" *: *"\(v[0-9.]*\)".*/\1/p' | head -n1 || true)
if [[ -z "$VREL" ]]; then VREL="v1.0.97"; fi
VTAR="ventoy-${VREL#v}-linux.tar.gz"
curl -fL -o "$VTAR" "https://github.com/ventoy/Ventoy/releases/download/$VREL/$VTAR"
tar xf "$VTAR"
VSDIR="ventoy-${VREL#v}"

echo "\nInstalling Ventoy to $DEV (this erases the drive)..."
sudo sh "$VSDIR/Ventoy2Disk.sh" -I "$DEV" -y

echo "\nMounting Ventoy data partition (${DEV}1) to $MNT..."
sudo mkdir -p "$MNT"
sudo mount "${DEV}1" "$MNT"

echo "Labeling volume as $LABEL (best-effort)..."
if command -v exfatlabel >/dev/null 2>&1; then
  sudo exfatlabel "${DEV}1" "$LABEL" || true
fi

echo "\nDownloading Ubuntu ISO..."
cd "$MNT"
curl -fLO "$UBUNTU_ISO_URL"

echo "\nAdding RadiateOS branding/config..."
sudo mkdir -p "$MNT/ventoy/theme"
curl -fsSL "$THEME_JSON_URL" | sudo tee "$MNT/ventoy/ventoy.json" >/dev/null
curl -fsSL "$THEME_TXT_URL" | sudo tee "$MNT/ventoy/theme/theme.txt" >/dev/null

echo "\nSyncing and unmounting..."
sync
cd /
sudo umount "$MNT"

echo "\nDone. USB is ready: $DEV"
echo "Boot it and select Ubuntu in the 'RadiateOS 1.0 Boot Menu'."

