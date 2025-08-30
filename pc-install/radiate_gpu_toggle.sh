#!/usr/bin/env bash
set -euo pipefail

# RadiateOS GPU quick toggle
# Usage:
#   radiate-gpu mode [on_demand|nvidia_only|intel_only|auto]
#   radiate-gpu power [throttled|balanced|performance]
#   radiate-gpu status

CONFIG_FILE=/etc/radiateos/pc-config.env

ensure_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "Please run as root: sudo $0 $*" >&2
    exit 1
  fi
}

set_config() {
  local key="$1" val="$2"
  mkdir -p "$(dirname "$CONFIG_FILE")"
  if [[ -f "$CONFIG_FILE" && $(grep -c "^${key}=" "$CONFIG_FILE" || true) -gt 0 ]]; then
    sed -i.bak "s|^${key}=.*|${key}=${val}|" "$CONFIG_FILE"
  else
    echo "${key}=${val}" >> "$CONFIG_FILE"
  fi
}

restart_kiosk() {
  systemctl daemon-reload || true
  systemctl restart radiateos-kiosk.service || true
}

cmd=${1:-}
arg=${2:-}

case "$cmd" in
  mode)
    ensure_root "$@"
    case "$arg" in
      on_demand|nvidia_only|intel_only|auto)
        set_config GPU_MODE "$arg"
        if command -v prime-select >/dev/null 2>&1; then
          case "$arg" in
            on_demand) prime-select on-demand || true ;;
            nvidia_only) prime-select nvidia || true ;;
            intel_only) prime-select intel || true ;;
            auto) prime-select on-demand || true ;;
          esac
        fi
        # Update kiosk wrapper if applicable
        source "$CONFIG_FILE" 2>/dev/null || true
        KIOSK_ENV=/etc/radiateos/kiosk.env
        if [[ -f "$KIOSK_ENV" ]]; then
          # shellcheck disable=SC1090
          . "$KIOSK_ENV"
          if command -v gpu-run >/dev/null 2>&1; then
            case "$arg" in
              on_demand|nvidia_only)
                EXEC_CMD="gpu-run ${EXEC_CMD#gpu-run }" ;;
              *)
                EXEC_CMD="${EXEC_CMD#gpu-run }" ;;
            esac
            echo "EXEC_CMD=$EXEC_CMD" > "$KIOSK_ENV"
          fi
        fi
        restart_kiosk
        echo "GPU mode set to: $arg"
        ;;
      *) echo "Usage: $0 mode [on_demand|nvidia_only|intel_only|auto]" >&2; exit 1 ;;
    esac
    ;;
  power)
    ensure_root "$@"
    case "$arg" in
      throttled|balanced|performance)
        set_config POWER_PROFILE "$arg"
        bash -euo pipefail /usr/local/bin/nvidia_power_profile.sh "$arg" || true
        echo "Power profile set to: $arg"
        ;;
      *) echo "Usage: $0 power [throttled|balanced|performance]" >&2; exit 1 ;;
    esac
    ;;
  status)
    # Print current config, PRIME mode, kiosk ExecStart, and NVIDIA power info
    THEME=""; GPU_MODE=""; BROWSER_GPU=""; POWER_PROFILE=""
    if [[ -f "$CONFIG_FILE" ]]; then
      # shellcheck disable=SC1090
      . "$CONFIG_FILE"
    fi
    echo "RadiateOS GPU Status"
    echo "---------------------"
    echo "Theme:           ${THEME:-unknown}"
    echo "GPU_MODE:        ${GPU_MODE:-unknown}"
    echo "BROWSER_GPU:     ${BROWSER_GPU:-unknown}"
    echo "POWER_PROFILE:   ${POWER_PROFILE:-unknown}"
    if command -v prime-select >/dev/null 2>&1; then
      PRIME_CUR=$(prime-select query 2>/dev/null || echo unknown)
      echo "PRIME mode:      ${PRIME_CUR}"
    fi
    KIOSK_ENV=/etc/radiateos/kiosk.env
    if [[ -f "$KIOSK_ENV" ]]; then
      # shellcheck disable=SC1090
      . "$KIOSK_ENV"
      echo "Kiosk Exec:      ${EXEC_CMD:-unset}"
      if [[ "${EXEC_CMD:-}" == gpu-run* ]]; then
        echo "Kiosk GPU wrap:  enabled"
      else
        echo "Kiosk GPU wrap:  disabled"
      fi
    else
      echo "Kiosk Exec:      not configured"
    fi
    if command -v nvidia-smi >/dev/null 2>&1; then
      INFO=$(nvidia-smi -q -d POWER 2>/dev/null || true)
      if [[ -n "$INFO" ]]; then
        CUR=$(echo "$INFO" | grep -m1 "Power Draw" | awk -F":" '{print $2}' | xargs)
        LIM=$(echo "$INFO" | grep -m1 "Power Limit" | awk -F":" '{print $2}' | xargs)
        MIN=$(echo "$INFO" | grep -m1 "Min Power Limit" | awk -F":" '{print $2}' | xargs)
        MAX=$(echo "$INFO" | grep -m1 "Max Power Limit" | awk -F":" '{print $2}' | xargs)
        PERS=$(nvidia-smi -q 2>/dev/null | grep -m1 "Persistence Mode" | awk -F":" '{print $2}' | xargs)
        echo "NVIDIA Power:    draw=${CUR:-n/a}, limit=${LIM:-n/a}, min=${MIN:-n/a}, max=${MAX:-n/a}, persistence=${PERS:-n/a}"
      else
        echo "NVIDIA Power:    unavailable"
      fi
    else
      echo "NVIDIA:          nvidia-smi not found"
    fi
    exit 0
    ;;
  *)
    cat <<USAGE >&2
Usage:
  $0 mode [on_demand|nvidia_only|intel_only|auto]
  $0 power [throttled|balanced|performance]
  $0 status
USAGE
    exit 1
    ;;
esac

exit 0
