#!/usr/bin/env bash
set -euo pipefail

# RadiateOS GPU quick toggle
# Usage:
#   radiate-gpu mode [on_demand|nvidia_only|intel_only|auto]
#   radiate-gpu power [throttled|balanced|performance]

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
  *)
    cat <<USAGE >&2
Usage:
  $0 mode [on_demand|nvidia_only|intel_only|auto]
  $0 power [throttled|balanced|performance]
USAGE
    exit 1
    ;;
esac

exit 0

