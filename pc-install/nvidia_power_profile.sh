#!/usr/bin/env bash
set -euo pipefail

# RadiateOS NVIDIA Power Profile helper
# - Sets power limit according to POWER_PROFILE: throttled|balanced|performance
# - Safe no-op if NVIDIA GPU or capabilities are unavailable

GPU_INDEX=${GPU_INDEX:-0}
CONFIG_FILE=${CONFIG_FILE:-/etc/radiateos/pc-config.env}

PROFILE_ARG=${1:-}

if [[ -z "${PROFILE_ARG}" && -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  . "$CONFIG_FILE"
  PROFILE_ARG=${POWER_PROFILE:-balanced}
fi

PROFILE=${PROFILE_ARG:-balanced}

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "nvidia-smi not found; skipping power profile" >&2
  exit 0
fi

# Query power limits
INFO=$(nvidia-smi -i "$GPU_INDEX" -q -d POWER 2>/dev/null || true)
if [[ -z "$INFO" ]]; then
  echo "Unable to query NVIDIA power info; skipping" >&2
  exit 0
fi

parse_watts() {
  awk -F":" 'NR==1{gsub(/W|w|\\s/ ,"", $2); v=$2; sub(/\..*/,"",v); print v}'
}

MIN=$(echo "$INFO" | grep -m1 "Min Power Limit" | parse_watts || true)
MAX=$(echo "$INFO" | grep -m1 "Max Power Limit" | parse_watts || true)
DEF=$(echo "$INFO" | grep -m1 "Default Power Limit" | parse_watts || true)

if [[ -z "$MIN" || -z "$MAX" ]]; then
  echo "Power limit range not available; skipping" >&2
  exit 0
fi

# Compute target limit
TARGET=$DEF
case "$PROFILE" in
  throttled)
    TARGET=$MIN ;;
  balanced)
    # midpoint between min and max
    TARGET=$(( (MIN + MAX) / 2 )) ;;
  performance)
    TARGET=$MAX ;;
  *)
    TARGET=$DEF ;;
esac

echo "Setting NVIDIA persistence mode and power limit (GPU $GPU_INDEX): $TARGET W ($PROFILE)"
nvidia-smi -i "$GPU_INDEX" -pm 1 >/dev/null 2>&1 || true
nvidia-smi -i "$GPU_INDEX" -pl "$TARGET" >/dev/null 2>&1 || {
  echo "Failed to set power limit; device may not support changing it" >&2
  exit 0
}

exit 0

