#!/bin/bash
# System Health Check — Archlinux + Hyprland
# Usage: ./check.sh [--minimal|--rice|--full]

GREEN='\033[0;32m' YELLOW='\033[1;33m' RED='\033[0;31m'
BLUE='\033[0;34m' CYAN='\033[0;36m' NC='\033[0m'

ok=0 warn=0 fail=0

CHECK_MODE="auto"
case "${1:-}" in
    --minimal) CHECK_MODE="minimal" ;;
    --rice)    CHECK_MODE="rice" ;;
    --dev)     CHECK_MODE="dev" ;;
    --full)    CHECK_MODE="full" ;;
esac

check_cmd() {
    local name="$1" cmd="$2" level="${3:-required}"
    if command -v "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}[OK]${NC}   $name"; ((ok++))
    elif [ "$level" = "optional" ]; then
        echo -e "  ${YELLOW}[WARN]${NC} $name — not installed (optional)"; ((warn++))
    else
        echo -e "  ${RED}[FAIL]${NC} $name — missing!"; ((fail++))
    fi
}

check_pkg() {
    local name="$1" pkg="$2" level="${3:-required}"
    if pacman -Qi "$pkg" &>/dev/null; then
        echo -e "  ${GREEN}[OK]${NC}   $name"; ((ok++))
    elif [ "$level" = "optional" ]; then
        echo -e "  ${YELLOW}[WARN]${NC} $name — not installed (optional)"; ((warn++))
    else
        echo -e "  ${RED}[FAIL]${NC} $name — missing package: $pkg"; ((fail++))
    fi
}

check_service() {
    local name="$1" svc="$2"
    if systemctl is-enabled --quiet "$svc" 2>/dev/null && systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo -e "  ${GREEN}[OK]${NC}   $name (enabled & active)"; ((ok++))
    elif systemctl is-enabled --quiet "$svc" 2>/dev/null; then
        echo -e "  ${YELLOW}[WARN]${NC} $name (enabled but inactive)"; ((warn++))
    else
        echo -e "  ${YELLOW}[WARN]${NC} $name (not enabled)"; ((warn++))
    fi
}

echo -e "\n${CYAN}══ System Health Check — Archlinux + Hyprland ══${NC}\n"

# 1. Core Components
echo -e "${CYAN}── Core Components ──${NC}"
check_cmd "lspci (pciutils)"    "lspci"
check_cmd "Hyprland"            "Hyprland"
check_cmd "Foot terminal"       "foot"
check_cmd "Fish shell"          "fish"
check_cmd "Fuzzel launcher"     "fuzzel"
check_cmd "Thunar file manager" "thunar"

# 2. Wayland & Display
echo -e "\n${CYAN}── Wayland & Display ──${NC}"
for pair in "Hyprlock:hyprlock" "Hypridle:hypridle" "grim:grim" "slurp:slurp" "wl-copy:wl-copy" "cliphist:cliphist" "brightnessctl:brightnessctl"; do
    check_cmd "${pair%%:*}" "${pair##*:}"
done

# 3. Audio
echo -e "\n${CYAN}── Audio ──${NC}"
check_pkg "PipeWire"    "pipewire"
check_pkg "WirePlumber" "wireplumber"
check_cmd "pavucontrol" "pavucontrol"
check_cmd "playerctl"   "playerctl"

# 4. Networking
echo -e "\n${CYAN}── Networking ──${NC}"
check_service "NetworkManager" "NetworkManager"
check_service "Bluetooth"      "bluetooth"

# 5. GPU & Driver Detection
echo -e "\n${CYAN}── GPU & Driver Detection ──${NC}"
if command -v lspci &>/dev/null; then
    GPU_INFO="$(lspci | grep -Ei 'vga|3d|display')"
    if echo "$GPU_INFO" | grep -iq 'nvidia'; then
        echo -e "  ${GREEN}[OK]${NC}   NVIDIA GPU detected"
        if pacman -Qi nvidia-dkms &>/dev/null || pacman -Qi nvidia-open-dkms &>/dev/null; then
            echo -e "  ${GREEN}[OK]${NC}   NVIDIA driver installed"; ((ok++))
        else
            echo -e "  ${RED}[FAIL]${NC} nvidia-dkms or nvidia-open-dkms missing"; ((fail++))
        fi
        check_pkg "nvidia-utils" "nvidia-utils"
    elif echo "$GPU_INFO" | grep -iq 'amd'; then
        echo -e "  ${GREEN}[OK]${NC}   AMD GPU detected"
        check_pkg "vulkan-radeon" "vulkan-radeon"
    elif echo "$GPU_INFO" | grep -iq 'intel'; then
        echo -e "  ${GREEN}[OK]${NC}   Intel GPU detected"
        check_pkg "vulkan-intel" "vulkan-intel"
    else
        echo -e "  ${YELLOW}[WARN]${NC} VMware / Generic GPU — using fallback profile"
    fi
fi

if [ -f "$HOME/.config/hypr/env-gpu.conf" ]; then
    echo -e "  ${GREEN}[OK]${NC}   GPU env profile installed"; ((ok++))
else
    echo -e "  ${RED}[FAIL]${NC} GPU env profile missing (~/.config/hypr/env-gpu.conf)"; ((fail++))
fi

# 6. Rice & Theming
echo -e "\n${CYAN}── Rice & Theming ──${NC}"
HAS_RICE=false
[[ "$CHECK_MODE" =~ ^(rice|full)$ ]] || command -v caelestia &>/dev/null && HAS_RICE=true

if [ "$HAS_RICE" = true ]; then
    echo -e "  ${BLUE}[INFO]${NC} Rice profile detected"
    for pair in "Caelestia CLI:caelestia" "Fastfetch:fastfetch" "Cava:cava" "Waypaper:waypaper" "Viewnior:viewnior" "Mako:mako" "swappy:swappy" "Starship:starship"; do
        name="${pair%%:*}" cmd="${pair##*:}"
        [ "$name" = "Caelestia CLI" ] && check_cmd "$name" "$cmd" || check_cmd "$name" "$cmd" optional
    done
else
    echo -e "  ${BLUE}[INFO]${NC} Minimal profile active"
    check_cmd "Mako"     "mako"     optional
    check_cmd "Starship" "starship" optional
fi

# 7. Extras
echo -e "\n${CYAN}── Extras & AUR ──${NC}"
check_cmd "yay (AUR)"  "yay"
check_cmd "momoisay"   "momoisay"  optional
check_cmd "Firefox"    "firefox"   optional

# 8. Config Files
echo -e "\n${CYAN}── Core Config Files ──${NC}"
core_configs=(hypr/hyprland.conf hypr/env.conf hypr/env-gpu.conf hypr/hypridle.conf foot/foot.ini fuzzel/fuzzel.ini fish/config.fish)
for cfg in "${core_configs[@]}"; do
    if [ -f "$HOME/.config/$cfg" ]; then
        echo -e "  ${GREEN}[OK]${NC}   $cfg"; ((ok++))
    else
        echo -e "  ${RED}[FAIL]${NC} $cfg — missing"; ((fail++))
    fi
done

if [ "$HAS_RICE" = true ]; then
    echo -e "\n${CYAN}── Rice Config Files ──${NC}"
    rice_configs=(caelestia/hypr-vars.lua caelestia/hypr-user.conf cava/config fastfetch/config.jsonc waypaper/config.ini)
    for cfg in "${rice_configs[@]}"; do
        if [ -f "$HOME/.config/$cfg" ]; then
            echo -e "  ${GREEN}[OK]${NC}   $cfg"; ((ok++))
        else
            echo -e "  ${YELLOW}[WARN]${NC} $cfg — not found"; ((warn++))
        fi
    done
fi

# 9. Hyprland Runtime
if command -v hyprctl &>/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo -e "\n${CYAN}── Hyprland Runtime ──${NC}"
    config_errs="$(hyprctl configerrors 2>/dev/null || true)"
    if echo "$config_errs" | grep -q '^Config error'; then
        echo -e "  ${RED}[FAIL]${NC} Hyprland config errors:"; echo "$config_errs" | head -5; ((fail++))
    else
        echo -e "  ${GREEN}[OK]${NC}   Hyprland config OK"; ((ok++))
    fi
fi

# Summary
echo -e "\n${CYAN}══════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}OK: $ok${NC}  ${YELLOW}WARN: $warn${NC}  ${RED}FAIL: $fail${NC}"
[ "$fail" -eq 0 ] && echo -e "  ${GREEN}✔ System health check passed!${NC}" || echo -e "  ${RED}⚠ Some components missing. Run ./install.sh to fix.${NC}"
echo -e "${CYAN}══════════════════════════════════════════════${NC}\n"
exit "$fail"
