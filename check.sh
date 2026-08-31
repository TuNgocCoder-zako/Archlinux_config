#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║  System Health Check — Archlinux + Hyprland              ║
# ║  Verifies all required components & configs              ║
# ╚══════════════════════════════════════════════════════════╝

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

ok=0
warn=0
fail=0

check_cmd() {
    local name="$1"
    local cmd="$2"
    local level="${3:-required}"  # required | optional

    if command -v "$cmd" &> /dev/null; then
        echo -e "  ${GREEN}[OK]${NC}   $name"
        ((ok++))
    elif [ "$level" = "optional" ]; then
        echo -e "  ${YELLOW}[WARN]${NC} $name — not installed (optional)"
        ((warn++))
    else
        echo -e "  ${RED}[FAIL]${NC} $name — missing!"
        ((fail++))
    fi
}

check_pkg() {
    local name="$1"
    local pkg="$2"
    local level="${3:-required}"

    if pacman -Qi "$pkg" &> /dev/null; then
        echo -e "  ${GREEN}[OK]${NC}   $name"
        ((ok++))
    elif [ "$level" = "optional" ]; then
        echo -e "  ${YELLOW}[WARN]${NC} $name — not installed (optional)"
        ((warn++))
    else
        echo -e "  ${RED}[FAIL]${NC} $name — missing package: $pkg"
        ((fail++))
    fi
}

check_service() {
    local name="$1"
    local svc="$2"

    if systemctl is-enabled --quiet "$svc" 2>/dev/null && systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo -e "  ${GREEN}[OK]${NC}   $name (enabled & active)"
        ((ok++))
    elif systemctl is-enabled --quiet "$svc" 2>/dev/null; then
        echo -e "  ${YELLOW}[WARN]${NC} $name (enabled but inactive)"
        ((warn++))
    else
        echo -e "  ${YELLOW}[WARN]${NC} $name (not enabled)"
        ((warn++))
    fi
}

echo -e "\n${CYAN}══════════════════════════════════════════════${NC}"
echo -e "${CYAN}  System Health Check — Archlinux + Hyprland${NC}"
echo -e "${CYAN}══════════════════════════════════════════════${NC}\n"

# ── Core Components ──
echo -e "${CYAN}── Core Components ──${NC}"
check_cmd "lspci (pciutils)"  "lspci"
check_cmd "Hyprland"          "Hyprland"
check_cmd "Foot terminal"     "foot"
check_cmd "Fish shell"        "fish"
check_cmd "Fuzzel launcher"   "fuzzel"
check_cmd "Mako notifications" "mako" optional
check_cmd "Thunar file manager" "thunar"

# ── Wayland & Display ──
echo -e "\n${CYAN}── Wayland & Display ──${NC}"
check_cmd "Hyprlock"          "hyprlock"
check_cmd "Hypridle"          "hypridle"
check_cmd "grim (screenshot)" "grim"
check_cmd "slurp (select)"    "slurp"
check_cmd "wl-copy"           "wl-copy"
check_cmd "cliphist"          "cliphist"
check_cmd "swappy"            "swappy"            optional
check_cmd "brightnessctl"     "brightnessctl"

# ── Audio ──
echo -e "\n${CYAN}── Audio ──${NC}"
check_pkg "PipeWire"          "pipewire"
check_pkg "WirePlumber"       "wireplumber"
check_cmd "pavucontrol"       "pavucontrol"
check_cmd "playerctl"         "playerctl"

# ── Networking ──
echo -e "\n${CYAN}── Networking ──${NC}"
check_service "NetworkManager"    "NetworkManager"
check_service "Bluetooth"         "bluetooth"

# ── Rice & Theming (Optional / Rice Profile) ──
echo -e "\n${CYAN}── Rice & Theming ──${NC}"
check_cmd "Caelestia CLI"     "caelestia"         optional
check_cmd "Fastfetch"         "fastfetch"         optional
check_cmd "Cava visualizer"   "cava"              optional
check_cmd "Waypaper"          "waypaper"           optional
check_cmd "Viewnior"          "viewnior"           optional
check_cmd "Starship prompt"   "starship"           optional

# ── GPU & Driver Detection ──
echo -e "\n${CYAN}── GPU & Driver Detection ──${NC}"
if command -v lspci &>/dev/null && lspci | grep -Ei 'vga|3d|display' | grep -iq 'nvidia'; then
    echo -e "  ${GREEN}[OK]${NC}   NVIDIA GPU detected"
    if pacman -Qi nvidia-dkms &>/dev/null; then
        echo -e "  ${GREEN}[OK]${NC}   nvidia-dkms installed"
        ((ok++))
    elif pacman -Qi nvidia-open-dkms &>/dev/null; then
        echo -e "  ${GREEN}[OK]${NC}   nvidia-open-dkms installed"
        ((ok++))
    else
        echo -e "  ${RED}[FAIL]${NC} nvidia-dkms or nvidia-open-dkms missing"
        ((fail++))
    fi
    check_pkg "nvidia-utils"  "nvidia-utils"
elif command -v lspci &>/dev/null && lspci | grep -Ei 'vga|3d|display' | grep -iq 'amd'; then
    echo -e "  ${GREEN}[OK]${NC}   AMD GPU detected"
    check_pkg "vulkan-radeon" "vulkan-radeon"
elif command -v lspci &>/dev/null && lspci | grep -Ei 'vga|3d|display' | grep -iq 'intel'; then
    echo -e "  ${GREEN}[OK]${NC}   Intel GPU detected"
    check_pkg "vulkan-intel"  "vulkan-intel"
else
    echo -e "  ${YELLOW}[WARN]${NC} VMware / Generic GPU — using fallback profile"
fi

# Unified GPU env profile check (created by installer for ALL GPUs)
if [ -f "$HOME/.config/hypr/env-gpu.conf" ]; then
    echo -e "  ${GREEN}[OK]${NC}   GPU env profile installed (~/.config/hypr/env-gpu.conf)"
    ((ok++))
else
    echo -e "  ${RED}[FAIL]${NC} GPU env profile missing (~/.config/hypr/env-gpu.conf)"
    ((fail++))
fi

# ── Extras ──
echo -e "\n${CYAN}── Extras ──${NC}"
check_cmd "momoisay"          "momoisay"           optional
check_cmd "Firefox"           "firefox"            optional
check_cmd "yay (AUR)"        "yay"

# ── Config Files ──
echo -e "\n${CYAN}── Core Config Files ──${NC}"
core_configs=(
    "$HOME/.config/hypr/env.conf"
    "$HOME/.config/hypr/env-gpu.conf"
    "$HOME/.config/hypr/hypridle.conf"
    "$HOME/.config/foot/foot.ini"
    "$HOME/.config/fuzzel/fuzzel.ini"
    "$HOME/.config/fish/config.fish"
)
for cfg in "${core_configs[@]}"; do
    name="$(basename "$(dirname "$cfg")")/$(basename "$cfg")"
    if [ -f "$cfg" ]; then
        echo -e "  ${GREEN}[OK]${NC}   $name"
        ((ok++))
    else
        echo -e "  ${RED}[FAIL]${NC} $name — missing"
        ((fail++))
    fi
done

# ── Hyprland Runtime Syntax Check (if inside session) ──
if command -v hyprctl &>/dev/null && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
    echo -e "\n${CYAN}── Hyprland Runtime ──${NC}"
    config_errs="$(hyprctl configerrors 2>/dev/null || true)"
    if echo "$config_errs" | grep -q '^Config error'; then
        echo -e "  ${RED}[FAIL]${NC} Hyprland configuration errors detected:"
        echo "$config_errs" | head -n 5
        ((fail++))
    else
        echo -e "  ${GREEN}[OK]${NC}   Hyprland config parsed without syntax errors"
        ((ok++))
    fi
fi

# ── Summary ──
echo -e "\n${CYAN}══════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}OK: $ok${NC}  ${YELLOW}WARN: $warn${NC}  ${RED}FAIL: $fail${NC}"
if [ "$fail" -eq 0 ]; then
    echo -e "  ${GREEN}✔ System is ready!${NC}"
else
    echo -e "  ${RED}⚠ Some components are missing. Run ./install.sh to fix.${NC}"
fi
echo -e "${CYAN}══════════════════════════════════════════════${NC}\n"

exit "$fail"
