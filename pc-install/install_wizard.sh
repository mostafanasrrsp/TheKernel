#!/usr/bin/env bash
set -euo pipefail

# RadiateOS PC Install Wizard (Win98/XP/Vista-inspired TUI)
# - Guides GPU mode, browser acceleration, and power profile
# - Adds retro themes with colorful ASCII splashes and palette preview

if ! command -v whiptail >/dev/null 2>&1; then
  echo "Installing whiptail (newt)..." >&2
  apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y whiptail >/dev/null 2>&1 || true
fi

# ANSI color helpers (fallback if tput not available)
if command -v tput >/dev/null 2>&1; then
  NC="$(tput sgr0)"; BOLD="$(tput bold)"
else
  NC="\033[0m"; BOLD="\033[1m"
fi
color() { printf "\033[%sm" "$1" 2>/dev/null || true; }

title="RadiateOS 1.0 Setup"
backtitle="RadiateOS • Classic Installer"

# Themed ASCII splashes
ascii_98='============================================================
 __   __      _ _           _           ____   __   __  
 \ \ / /__ _ (_) |__  _ __ (_) ___ ___ |  _ \  \ \ / /  
  \ V / _` | | |  _ \|  _ \| |/ __/ _ \| |_) |  \ V /   
   | | (_| | | | |_) | | | | | (_|  __/|  _ <    | |    
   |_|\__,_| |_|_.__/|_| |_|_|\___\___||_| \_\   |_|    
============================================================'

ascii_xp='============================================================
  ____            _ _ _           ____   ____   
 |  _ \ __ _  ___(_) | | ___ _ __|  _ \ / ___|  
 | |_) / _` |/ __| | | |/ _ \  __| |_) | |      
 |  __/ (_| | (__| | | |  __/ |  |  _ <| |___   
 |_|   \__,_|\___|_|_|_|\___|_|  |_| \_\\____|  
============================================================'

ascii_vista='============================================================
  _____ _     _     _           ____   _       _           
 |  __ (_)   | |   | |         / __ \ | |     | |          
 | |__) |  __| | __| | ___ _ _| |  | || |_ ___| |__   __ _ 
 |  ___/ |/ _` |/ _` |/ _ \  _| |  | || __/ __|  _ \ / _` |
 | |   | | (_| | (_| |  __/ | | |__| || |_\__ \ | | | (_| |
 |_|   |_|\__,_|\__,_|\___|_|  \____/  \__|___/_| |_|\__,_|
============================================================'

draw_splash() {
  local theme="${1:-98}"
  case "$theme" in
    98)
      printf "%s%s%s\n" "$(color 36; color 1)" "$ascii_98" "$NC" ;;
    xp)
      printf "%s%s%s\n" "$(color 34; color 1)" "$ascii_xp" "$NC" ;;
    vista)
      printf "%s%s%s\n" "$(color 32; color 1)" "$ascii_vista" "$NC" ;;
    *)
      printf "%s%s%s\n" "$(color 36; color 1)" "$ascii_98" "$NC" ;;
  esac
}

palette_preview() {
  local theme="$1"
  echo ""
  case "$theme" in
    98)
      echo -e "$(color 37; color 1)Classic 98 Palette$(color 0)" || true
      echo -e "$(color 37)■ $(color 37)Silver  $(color 32)■ $(color 32)Green  $(color 34)■ $(color 34)Blue  $(color 31)■ $(color 31)Red$(color 0)" || true ;;
    xp)
      echo -e "$(color 37; color 1)XP Luna Palette$(color 0)" || true
      echo -e "$(color 34)■ $(color 34)Blue  $(color 33)■ $(color 33)Olive  $(color 36)■ $(color 36)Teal  $(color 35)■ $(color 35)Purple$(color 0)" || true ;;
    vista)
      echo -e "$(color 37; color 1)Vista Aero Palette$(color 0)" || true
      echo -e "$(color 36)■ $(color 36)Cyan  $(color 32)■ $(color 32)Emerald  $(color 34)■ $(color 34)Navy  $(color 37)■ $(color 37)Glass$(color 0)" || true ;;
  esac
  echo ""
}

THEME=${THEME:-xp}
GPU_MODE=${GPU_MODE:-auto}
BROWSER_GPU=${BROWSER_GPU:-on}
POWER_PROFILE=${POWER_PROFILE:-balanced}

clear
draw_splash "$THEME"
echo -e "${BOLD}Welcome to RadiateOS 1.0 – Classic Setup Wizard${NC}\n"

if command -v whiptail >/dev/null 2>&1; then
  # Theme selection
  THEME=$(whiptail --title "$title" --backtitle "$backtitle" \
    --menu "Choose your classic theme:" 20 72 6 \
    xp "Windows XP • Luna Blue" \
    98 "Windows 98 • Classic Gray" \
    vista "Windows Vista • Aero Glass" \
    3>&1 1>&2 2>&3) || true

  clear; draw_splash "$THEME"; palette_preview "$THEME"
  sleep 0.5

  # GPU Mode selection
  GPU_MODE=$(whiptail --title "$title" --backtitle "$backtitle" \
    --menu "Graphics Mode (Hybrid laptop friendly):" 20 72 5 \
    auto "Auto-detect (recommended)" \
    on_demand "Use iGPU; offload select apps to NVIDIA" \
    nvidia_only "Force NVIDIA for entire session" \
    intel_only "Force integrated only" \
    3>&1 1>&2 2>&3) || true

  BROWSER_GPU=$(whiptail --title "$title" --backtitle "$backtitle" \
    --yesno "Enable GPU acceleration for web browsing?" 12 72 \
    && echo on || echo off)

  POWER_PROFILE=$(whiptail --title "$title" --backtitle "$backtitle" \
    --menu "NVIDIA Power Profile (if supported):" 18 72 3 \
    throttled "Lower power/heat (limit clocks)" \
    balanced "Default (recommended)" \
    performance "Max clocks (more heat)" \
    3>&1 1>&2 2>&3) || true
else
  # Fallback to stdin prompts
  read -r -p "Theme [xp/98/vista] (xp): " THEME || true; THEME=${THEME:-xp}
  read -r -p "GPU Mode [auto/on_demand/nvidia_only/intel_only] (auto): " GPU_MODE || true; GPU_MODE=${GPU_MODE:-auto}
  read -r -p "Browser GPU acceleration? [on/off] (on): " BROWSER_GPU || true; BROWSER_GPU=${BROWSER_GPU:-on}
  read -r -p "Power profile [throttled/balanced/performance] (balanced): " POWER_PROFILE || true; POWER_PROFILE=${POWER_PROFILE:-balanced}
fi

clear; draw_splash "$THEME"; palette_preview "$THEME"
echo -e "${BOLD}Summary${NC}"
echo "• Theme:          $THEME"
echo "• GPU Mode:       $GPU_MODE"
echo "• Browser GPU:    $BROWSER_GPU"
echo "• Power Profile:  $POWER_PROFILE"
echo ""

# Persist choices
mkdir -p /etc/radiateos
cat >/etc/radiateos/pc-config.env <<EOF
THEME=$THEME
GPU_MODE=$GPU_MODE
BROWSER_GPU=$BROWSER_GPU
POWER_PROFILE=$POWER_PROFILE
EOF

echo "Saved configuration to /etc/radiateos/pc-config.env"

exit 0
