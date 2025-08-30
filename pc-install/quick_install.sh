#!/usr/bin/env bash
set -euo pipefail

# RadiateOS quick installer
# Downloads installer + helpers from GitHub and runs the main installer.

REPO="mostafanasrrsp/TheKernel"
REF="${RADIATE_REF:-main}"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${REF}"
WORKDIR="${TMPDIR:-/tmp}/radiateos-install"

FILES=(
  "INSTALL_ON_HP_PAVILION.sh:INSTALL_ON_HP_PAVILION.sh"
  "pc-install/gpu_offload_wrappers.sh:pc-install/gpu_offload_wrappers.sh"
  "pc-install/install_wizard.sh:pc-install/install_wizard.sh"
  "pc-install/nvidia_power_profile.sh:pc-install/nvidia_power_profile.sh"
  "pc-install/radiate_gpu_toggle.sh:pc-install/radiate_gpu_toggle.sh"
  "pc-install/radiate_tray.py:pc-install/radiate_tray.py"
  "pc-install/icons/radiate_tray.svg:pc-install/icons/radiate_tray.svg"
  "pc-install/polkit/com.radiateos.radiate-gpu.policy:pc-install/polkit/com.radiateos.radiate-gpu.policy"
)

echo "RadiateOS quick installer (ref: $REF)"
echo "Working in: $WORKDIR"
rm -rf "$WORKDIR" && mkdir -p "$WORKDIR"

download() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$WORKDIR/$dst")"
  echo "Fetching: $src -> $dst"
  curl -fsSL "$BASE_URL/$src" -o "$WORKDIR/$dst"
}

for spec in "${FILES[@]}"; do
  src="${spec%%:*}"; dst="${spec##*:}"
  download "$src" "$dst"
done

chmod +x "$WORKDIR/INSTALL_ON_HP_PAVILION.sh"
echo "Running installer as root..."
sudo env BASE_DIR="$WORKDIR" bash -euo pipefail "$WORKDIR/INSTALL_ON_HP_PAVILION.sh"

