#!/usr/bin/env bash
set -euo pipefail

# Install GPU offload wrappers and browser launchers

install_wrapper() {
  local path="$1"; shift
  install -m 0755 /dev/stdin "$path" <<'WRAP'
#!/usr/bin/env bash
set -euo pipefail

# Generic NVIDIA PRIME Render Offload wrapper
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
exec "$@"
WRAP
}

# Create generic gpu-run
install_wrapper /usr/local/bin/gpu-run

# Chromium with GPU flags (snap or apt)
cat >/usr/local/bin/chromium-gpu <<'CHROM'
#!/usr/bin/env bash
set -euo pipefail
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
FLAGS=(
  --use-gl=desktop
  --enable-gpu-rasterization
  --enable-zero-copy
  --ignore-gpu-blocklist
  --enable-features=VaapiVideoDecoder,CanvasOopRasterization,WebAssemblyLazyCompilation
)
if command -v chromium >/dev/null 2>&1; then
  exec chromium "${FLAGS[@]}" "$@"
elif command -v chromium-browser >/dev/null 2>&1; then
  exec chromium-browser "${FLAGS[@]}" "$@"
else
  echo "Chromium not found. Install chromium-browser first." >&2
  exit 1
fi
CHROM
chmod +x /usr/local/bin/chromium-gpu

# Optional: Firefox GPU launch (Wayland/VAAPI where available)
cat >/usr/local/bin/firefox-gpu <<'FF'
#!/usr/bin/env bash
set -euo pipefail
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
export MOZ_X11_EGL=1
export MOZ_DISABLE_RDD_SANDBOX=1
exec firefox "$@"
FF
chmod +x /usr/local/bin/firefox-gpu

echo "Installed GPU offload wrappers: gpu-run, chromium-gpu, firefox-gpu"

