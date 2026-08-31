#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║  Arch Linux + Hyprland + Caelestia Shell Installer       ║
# ║  Material You Dynamic Theming — Bare Metal Ready         ║
# ║                                                          ║
# ║  Usage:                                                  ║
# ║    ./install.sh              # Interactive (default)     ║
# ║    ./install.sh --minimal    # Core only (no rice/sddm)  ║
# ║    ./install.sh --rice       # Core + Caelestia Rice     ║
# ║    ./install.sh --full       # Core + Rice + Opt + Dev   ║
# ║    ./install.sh --dev        # Core + Dev tools          ║
# ╚══════════════════════════════════════════════════════════╝

set -Eeuo pipefail

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
PINK='\033[1;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_banner() {
    echo -e "${PINK}"
    echo "  ╔═══════════════════════════════════════════════╗"
    echo "  ║                                               ║"
    echo "  ║   🌸 Caelestia Shell Installer 🌸             ║"
    echo "  ║   Arch Linux + Hyprland + Material You         ║"
    echo "  ║                                               ║"
    echo "  ╚═══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  ❯ $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() { echo -e "${GREEN}  ✔ $1${NC}"; }
print_warning() { echo -e "${RED}  ⚠ $1${NC}"; }
print_info() { echo -e "${BLUE}  ℹ $1${NC}"; }

trap 'print_warning "Error on line $LINENO (exit status: $?)"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
PACKAGES_DIR="$SCRIPT_DIR/packages"

# ── Parse arguments ──
INSTALL_MODE="interactive"
case "${1:-}" in
    --minimal) INSTALL_MODE="minimal" ;;
    --rice)    INSTALL_MODE="rice" ;;
    --full)    INSTALL_MODE="full" ;;
    --dev)     INSTALL_MODE="dev" ;;
    --help|-h)
        echo "Usage: ./install.sh [--minimal|--rice|--full|--dev]"
        echo ""
        echo "  --minimal   Core only (Hyprland, Foot, Fish, PipeWire, GPU drivers)"
        echo "  --rice      Core + Caelestia Shell + Material You Theming"
        echo "  --full      Core + Rice + Optional (Firefox) + Dev tools"
        echo "  --dev       Core + development tools"
        echo "  (no flag)   Interactive mode — choose what to install"
        exit 0
        ;;
esac

# ── Helper: read packages from file ──
read_packages() {
    local file="$1"
    if [ ! -f "$file" ]; then
        print_warning "Package list not found: $file"
        return
    fi
    grep -v '^#' "$file" | grep -v '^$' | tr '\n' ' '
}

# ── Helper: backup config before overwriting ──
backup_config() {
    local target="$1"
    if [ -e "$target" ]; then
        local backup="${target}.backup.$(date +%Y%m%d-%H%M%S)"
        mv "$target" "$backup"
        print_info "Backed up: $(basename "$target") → $(basename "$backup")"
    fi
}

# ── Copy dotfiles with backup ──
copy_with_backup() {
    local src="$1"
    local dest="$2"
    if [ -f "$src" ]; then
        backup_config "$dest"
        cp -v "$src" "$dest"
    fi
}

print_banner

# ═══════════════════════════════════════════════
# Safety checks
# ═══════════════════════════════════════════════
if [ "$EUID" -eq 0 ]; then
    print_warning "Do NOT run as root! Run as your normal user."
    exit 1
fi

if [ "$INSTALL_MODE" = "interactive" ]; then
    echo -e "${PINK}This will install Arch Linux + Hyprland + Caelestia Shell.${NC}"
    echo -e "${PINK}Designed for bare metal machines (also works on VMware).${NC}"
    echo ""
    echo -e "${CYAN}Select install profile:${NC}"
    echo -e "  1) Minimal  — Core packages only (No rice/theming)"
    echo -e "  2) Rice     — Core + Caelestia Shell & theming"
    echo -e "  3) Full     — Core + Rice + Optional + Dev"
    echo -e "  4) Dev      — Core + development tools"
    echo ""
    read -r -p "Choose [1-4] (default: 2): " choice
    case "$choice" in
        1) INSTALL_MODE="minimal" ;;
        3) INSTALL_MODE="full" ;;
        4) INSTALL_MODE="dev" ;;
        *) INSTALL_MODE="rice" ;;
    esac
fi

INSTALL_RICE=false
if [ "$INSTALL_MODE" = "rice" ] || [ "$INSTALL_MODE" = "full" ]; then
    INSTALL_RICE=true
fi

print_info "Install mode: $INSTALL_MODE (Rice features: $INSTALL_RICE)"

# ═══════════════════════════════════════════════
# Step 1: System Update
# ═══════════════════════════════════════════════
print_step "Step 1/8: Updating system"
sudo pacman -Syu --noconfirm
print_success "System updated"

# ═══════════════════════════════════════════════
# Step 2: Install yay (AUR helper)
# ═══════════════════════════════════════════════
print_step "Step 2/8: Installing yay (AUR helper)"
if command -v yay &> /dev/null; then
    print_info "yay is already installed, skipping"
else
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    (cd /tmp/yay-bin && makepkg -si --noconfirm)
    rm -rf /tmp/yay-bin
    print_success "yay installed"
fi

# ═══════════════════════════════════════════════
# Step 3: Install packages from lists
# ═══════════════════════════════════════════════
print_step "Step 3/8: Installing packages ($INSTALL_MODE)"

# Always install core
PKGS="$(read_packages "$PACKAGES_DIR/core.txt")"

# Add extras based on mode
case "$INSTALL_MODE" in
    rice)
        PKGS="$PKGS $(read_packages "$PACKAGES_DIR/rice.txt")"
        ;;
    full)
        PKGS="$PKGS $(read_packages "$PACKAGES_DIR/rice.txt")"
        PKGS="$PKGS $(read_packages "$PACKAGES_DIR/optional.txt")"
        PKGS="$PKGS $(read_packages "$PACKAGES_DIR/dev.txt")"
        ;;
    dev)
        PKGS="$PKGS $(read_packages "$PACKAGES_DIR/dev.txt")"
        ;;
esac

# shellcheck disable=SC2086
sudo pacman -S --needed --noconfirm $PKGS
print_success "Packages installed ($INSTALL_MODE)"

# ═══════════════════════════════════════════════
# Step 4: GPU Drivers Auto-Detection
# ═══════════════════════════════════════════════
print_step "Step 4/8: Detecting GPU & Installing Drivers"

GPU_ENV_PROFILE=""

if lspci | grep -Ei 'vga|3d|display' | grep -iq 'nvidia'; then
    print_info "NVIDIA GPU detected — Installing nvidia-dkms drivers..."
    sudo pacman -S --needed --noconfirm \
        nvidia-dkms nvidia-utils lib32-nvidia-utils \
        libva-nvidia-driver egl-wayland nvidia-prime

    sudo systemctl enable nvidia-suspend.service 2>/dev/null || true
    sudo systemctl enable nvidia-hibernate.service 2>/dev/null || true
    sudo systemctl enable nvidia-resume.service 2>/dev/null || true
    GPU_ENV_PROFILE="env-nvidia.conf"
    print_success "NVIDIA drivers installed"

elif lspci | grep -Ei 'vga|3d|display' | grep -iq 'amd'; then
    print_info "AMD GPU detected — Installing Mesa & Vulkan..."
    sudo pacman -S --needed --noconfirm \
        xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon libva-mesa-driver
    GPU_ENV_PROFILE="env-amd.conf"
    print_success "AMD drivers installed"

elif lspci | grep -Ei 'vga|3d|display' | grep -iq 'intel'; then
    print_info "Intel GPU detected — Installing Vulkan & Media..."
    sudo pacman -S --needed --noconfirm \
        vulkan-intel lib32-vulkan-intel intel-media-driver
    GPU_ENV_PROFILE="env-intel.conf"
    print_success "Intel drivers installed"

else
    print_info "VMware or Generic GPU detected — using fallback profile"
    GPU_ENV_PROFILE="env-vmware.conf"
fi

# ═══════════════════════════════════════════════
# Step 5: Install Caelestia Shell (Rice / Full only)
# ═══════════════════════════════════════════════
print_step "Step 5/8: Desktop Shell & Themes"

if [ "$INSTALL_RICE" = true ]; then
    AUR_PKGS=(
        caelestia-cli
        papirus-icon-theme
        catppuccin-gtk-theme-mocha
        bibata-cursor-theme-bin
    )

    for pkg in "${AUR_PKGS[@]}"; do
        if pacman -Qi "$pkg" &> /dev/null; then
            print_info "$pkg already installed, skipping"
        else
            yay -S --noconfirm "$pkg" || print_warning "Failed to install $pkg"
        fi
    done

    print_info "Running Caelestia installer..."
    print_info "Recommended: select uwsm (8) for basic setup."
    caelestia install || print_warning "Caelestia installer finished with notices"
    print_success "Caelestia Shell installed"
else
    print_info "Skipping Caelestia Shell & AUR rice themes for $INSTALL_MODE profile"
fi

# ═══════════════════════════════════════════════
# Step 6: Backup & Copy dotfiles
# ═══════════════════════════════════════════════
print_step "Step 6/8: Backing up & copying dotfiles"

# Create common directories
mkdir -p ~/.config/{hypr,foot,fuzzel,fish,Thunar}
mkdir -p ~/.local/bin

# Hyprland env (common)
copy_with_backup "$DOTFILES_DIR/hypr/env.conf" ~/.config/hypr/env.conf
copy_with_backup "$DOTFILES_DIR/hypr/hypridle.conf" ~/.config/hypr/hypridle.conf

# GPU-specific env profile
if [ -n "$GPU_ENV_PROFILE" ] && [ -f "$DOTFILES_DIR/hypr/$GPU_ENV_PROFILE" ]; then
    backup_config "$HOME/.config/hypr/env-gpu.conf"
    cp -v "$DOTFILES_DIR/hypr/$GPU_ENV_PROFILE" ~/.config/hypr/env-gpu.conf
    print_success "GPU profile applied: $GPU_ENV_PROFILE → env-gpu.conf"

    # Ensure hyprland.conf sources it
    if ! grep -q 'env-gpu.conf' ~/.config/hypr/hyprland.conf 2>/dev/null; then
        echo 'source = ~/.config/hypr/env-gpu.conf' >> ~/.config/hypr/hyprland.conf 2>/dev/null || true
    fi
fi

# Base Terminal, Launcher, Fish, Thunar
copy_with_backup "$DOTFILES_DIR/foot/foot.ini" ~/.config/foot/foot.ini
copy_with_backup "$DOTFILES_DIR/fuzzel/fuzzel.ini" ~/.config/fuzzel/fuzzel.ini
copy_with_backup "$DOTFILES_DIR/fish/config.fish" ~/.config/fish/config.fish
copy_with_backup "$DOTFILES_DIR/Thunar/uca.xml" ~/.config/Thunar/uca.xml

# Rice dotfiles (only for rice / full)
if [ "$INSTALL_RICE" = true ]; then
    mkdir -p ~/.config/{caelestia,mako,gtk-3.0,fastfetch,cava,waypaper}
    mkdir -p ~/Pictures/Wallpapers

    copy_with_backup "$DOTFILES_DIR/caelestia/hypr-vars.lua" ~/.config/caelestia/hypr-vars.lua
    copy_with_backup "$DOTFILES_DIR/caelestia/hypr-user.conf" ~/.config/caelestia/hypr-user.conf
    copy_with_backup "$DOTFILES_DIR/mako/config" ~/.config/mako/config
    copy_with_backup "$DOTFILES_DIR/gtk-3.0/settings.ini" ~/.config/gtk-3.0/settings.ini
    copy_with_backup "$DOTFILES_DIR/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
    copy_with_backup "$DOTFILES_DIR/cava/config" ~/.config/cava/config
    copy_with_backup "$DOTFILES_DIR/waypaper/config.ini" ~/.config/waypaper/config.ini
fi

# Scripts
if [ -d "$SCRIPTS_DIR" ]; then
    cp -v "$SCRIPTS_DIR/"* ~/.local/bin/ 2>/dev/null || true
    chmod +x ~/.local/bin/*
fi

print_success "Dotfiles copied (old configs backed up with .backup.* suffix)"

# ═══════════════════════════════════════════════
# Step 7: SDDM Theme (Rice / Full only)
# ═══════════════════════════════════════════════
print_step "Step 7/8: Setting up Display Manager (SDDM)"

if [ "$INSTALL_RICE" = true ]; then
    sudo pacman -S --needed --noconfirm sddm qt5-graphicaleffects qt5-quickcontrols2 \
        qt5-svg qt6-svg qt6-declarative 2>/dev/null || true

    SDDM_TMP="/tmp/sddm-astronaut-theme-$$"
    SDDM_DEST="/usr/share/sddm/themes/sddm-astronaut-theme"

    # Clone to temp dir first — only replace if successful
    if sudo git clone https://github.com/Keyitdev/sddm-astronaut-theme.git "$SDDM_TMP" 2>/dev/null; then
        # Clone succeeded — safe to replace
        sudo rm -rf "$SDDM_DEST"
        sudo mv "$SDDM_TMP" "$SDDM_DEST"

        # Apply wallpaper & config
        if [ -f ~/Pictures/Wallpapers/emilia_dark.png ]; then
            sudo cp ~/Pictures/Wallpapers/emilia_dark.png "$SDDM_DEST/Backgrounds/emilia.png" 2>/dev/null || true
        fi
        sudo sed -i 's|^ConfigFile=.*|ConfigFile=Themes/pixel_sakura.conf|' "$SDDM_DEST/metadata.desktop" 2>/dev/null || true
        sudo sed -i 's/ScaleMode=.*/ScaleMode="Fill"/' "$SDDM_DEST/Themes/pixel_sakura.conf" 2>/dev/null || true

        sudo mkdir -p /etc/sddm.conf.d
        sudo bash -c 'cat << "EOF" > /etc/sddm.conf.d/theme.conf
[Theme]
Current=sddm-astronaut-theme
EOF'
        print_success "SDDM Astronaut theme configured"
    else
        # Clone failed — keep existing theme intact
        sudo rm -rf "$SDDM_TMP"
        print_warning "SDDM theme clone failed (network?). Existing theme preserved."
    fi
else
    print_info "Skipping SDDM display manager theme for $INSTALL_MODE profile"
fi

# ═══════════════════════════════════════════════
# Step 8: Enable services & finalize
# ═══════════════════════════════════════════════
print_step "Step 8/8: Enabling services & finalizing"

sudo systemctl enable --now NetworkManager 2>/dev/null || true
sudo systemctl enable --now bluetooth 2>/dev/null || true
sudo systemctl enable --now power-profiles-daemon 2>/dev/null || true

if [ "$INSTALL_RICE" = true ]; then
    sudo systemctl enable sddm 2>/dev/null || true
fi

# Set Fish as default shell
if [ "${SHELL:-}" != "$(which fish)" ]; then
    chsh -s "$(which fish)"
    print_success "Default shell changed to Fish"
fi

# Create user directories
xdg-user-dirs-update 2>/dev/null || true

# Download default wallpapers (Rice / Full only)
if [ "$INSTALL_RICE" = true ] && [ ! -f ~/Pictures/Wallpapers/emilia_dark.png ]; then
    print_info "Downloading default wallpapers..."
    curl -sL -o ~/Pictures/Wallpapers/emilia_dark.png \
        "https://raw.githubusercontent.com/doki-theme/doki-theme-assets/master/backgrounds/wallpapers/emilia_dark.png" 2>/dev/null || true
fi

print_success "Services enabled"

# ═══════════════════════════════════════════════
# Done!
# ═══════════════════════════════════════════════
echo ""
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PINK}"
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║                                               ║"
echo "  ║   🌸 Installation Complete! 🌸               ║"
echo "  ║                                               ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${CYAN}  Profile: ${PINK}$INSTALL_MODE${NC}"
echo -e "${CYAN}  GPU:     ${PINK}${GPU_ENV_PROFILE:-auto}${NC}"
echo ""
echo -e "${CYAN}  Next steps:${NC}"
echo -e "${GREEN}  1. Log out and log back in (or reboot)${NC}"
if [ "$INSTALL_RICE" = true ]; then
    echo -e "${GREEN}  2. Set wallpaper: ${PINK}caelestia wallpaper -f ~/Pictures/Wallpapers/emilia_dark.png${NC}"
fi
echo -e "${GREEN}  3. Run health check: ${PINK}./check.sh${NC}"
echo ""
echo -e "${CYAN}  Key bindings:${NC}"
echo -e "${GREEN}  Super + T / Super + Return →  Terminal (Foot)${NC}"
echo -e "${GREEN}  Super + D / Alt + D        →  App Launcher${NC}"
echo -e "${GREEN}  Super + V / Alt + V        →  Clipboard History${NC}"
echo -e "${GREEN}  Super + N / Alt + N        →  Sidebar / Control Center${NC}"
echo -e "${GREEN}  Super + Q / Alt + Q        →  Close window${NC}"
echo -e "${GREEN}  Super + E / Alt + E        →  File manager (Thunar)${NC}"
echo -e "${GREEN}  Super + L                  →  Lock screen${NC}"
echo ""
echo -e "${PURPLE}  Enjoy your Arch Linux + Hyprland setup! 🌸✨${NC}"
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
