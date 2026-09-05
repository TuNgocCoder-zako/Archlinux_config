#!/bin/bash
# Arch Linux + Hyprland + Caelestia Shell Installer
# Usage: ./install.sh [--minimal|--rice|--full|--dev]

set -Eeuo pipefail

# Colors
RED='\033[0;31m' GREEN='\033[0;32m' BLUE='\033[0;34m'
PURPLE='\033[0;35m' PINK='\033[1;35m' CYAN='\033[0;36m' NC='\033[0m'

print_banner() {
    echo -e "${PINK}\n  🌸 Caelestia Shell Installer 🌸"
    echo -e "  Arch Linux + Hyprland + Material You\n${NC}"
}
print_step()    { echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${CYAN}  ❯ $1${NC}\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
print_success() { echo -e "${GREEN}  ✔ $1${NC}"; }
print_warning() { echo -e "${RED}  ⚠ $1${NC}"; }
print_info()    { echo -e "${BLUE}  ℹ $1${NC}"; }

trap 'print_warning "Error on line $LINENO (exit status: $?)"' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
PACKAGES_DIR="$SCRIPT_DIR/packages"

# Parse arguments
INSTALL_MODE="interactive"
case "${1:-}" in
    --minimal) INSTALL_MODE="minimal" ;;
    --rice)    INSTALL_MODE="rice" ;;
    --full)    INSTALL_MODE="full" ;;
    --dev)     INSTALL_MODE="dev" ;;
    --help|-h)
        echo "Usage: ./install.sh [--minimal|--rice|--full|--dev]"
        echo "  --minimal   Core only (Hyprland, Foot, Fish, PipeWire, GPU drivers)"
        echo "  --rice      Core + Caelestia Shell + Material You Theming"
        echo "  --full      Core + Rice + Optional (Firefox) + Dev tools"
        echo "  --dev       Core + development tools"
        echo "  (no flag)   Interactive mode"
        exit 0 ;;
esac

read_packages() {
    local file="$1"
    [ ! -f "$file" ] && { print_warning "Package list not found: $file"; return; }
    grep -v '^#' "$file" | grep -v '^$' | tr '\n' ' '
}

backup_config() {
    local target="$1"
    if [ -e "$target" ]; then
        mv "$target" "${target}.backup.$(date +%Y%m%d-%H%M%S)"
        print_info "Backed up: $(basename "$target")"
    fi
}

copy_with_backup() {
    local src="$1" dest="$2"
    [ -f "$src" ] && { backup_config "$dest"; cp -v "$src" "$dest"; }
}

print_banner

# Safety check
if [ "$EUID" -eq 0 ]; then
    print_warning "Do NOT run as root! Run as your normal user."
    exit 1
fi

if [ "$INSTALL_MODE" = "interactive" ]; then
    echo -e "${CYAN}Select install profile:${NC}"
    echo "  1) Minimal  — Core packages only"
    echo "  2) Rice     — Core + Caelestia Shell & theming"
    echo "  3) Full     — Core + Rice + Optional + Dev"
    echo "  4) Dev      — Core + development tools"
    read -r -p "Choose [1-4] (default: 2): " choice
    case "$choice" in
        1) INSTALL_MODE="minimal" ;;
        3) INSTALL_MODE="full" ;;
        4) INSTALL_MODE="dev" ;;
        *) INSTALL_MODE="rice" ;;
    esac
fi

INSTALL_RICE=false
[[ "$INSTALL_MODE" =~ ^(rice|full)$ ]] && INSTALL_RICE=true

print_info "Install mode: $INSTALL_MODE (Rice features: $INSTALL_RICE)"

# Step 1: System Update
print_step "Step 1/8: Updating system"
sudo pacman -Syu --noconfirm
print_success "System updated"

# Step 2: Install yay (AUR helper)
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

# Step 3: Install packages from lists
print_step "Step 3/8: Installing packages ($INSTALL_MODE)"
PKGS="$(read_packages "$PACKAGES_DIR/core.txt")"
case "$INSTALL_MODE" in
    rice) PKGS="$PKGS $(read_packages "$PACKAGES_DIR/rice.txt")" ;;
    full) PKGS="$PKGS $(read_packages "$PACKAGES_DIR/rice.txt") $(read_packages "$PACKAGES_DIR/optional.txt") $(read_packages "$PACKAGES_DIR/dev.txt")" ;;
    dev)  PKGS="$PKGS $(read_packages "$PACKAGES_DIR/dev.txt")" ;;
esac
# shellcheck disable=SC2086
sudo pacman -S --needed --noconfirm $PKGS
print_success "Packages installed ($INSTALL_MODE)"

# Step 4: GPU Drivers Auto-Detection
print_step "Step 4/8: Detecting GPU & Installing Drivers"
GPU_ENV_PROFILE=""
GPU_INFO="$(lspci | grep -Ei 'vga|3d|display')"

if echo "$GPU_INFO" | grep -iq 'nvidia'; then
    print_info "NVIDIA GPU detected — Installing nvidia-dkms drivers..."
    sudo pacman -S --needed --noconfirm \
        nvidia-dkms nvidia-utils lib32-nvidia-utils \
        libva-nvidia-driver egl-wayland nvidia-prime
    sudo systemctl enable nvidia-{suspend,hibernate,resume}.service 2>/dev/null || true
    sudo mkdir -p /etc/modprobe.d
    echo "options nvidia_drm modeset=1 fbdev=1" | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null || true
    GPU_ENV_PROFILE="env-nvidia.conf"
    print_success "NVIDIA drivers & DRM modesetting configured"
elif echo "$GPU_INFO" | grep -iq 'amd'; then
    print_info "AMD GPU detected — Installing Mesa & Vulkan..."
    sudo pacman -S --needed --noconfirm \
        xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon libva-mesa-driver
    GPU_ENV_PROFILE="env-amd.conf"
    print_success "AMD drivers installed"
elif echo "$GPU_INFO" | grep -iq 'intel'; then
    print_info "Intel GPU detected — Installing Vulkan & Media..."
    sudo pacman -S --needed --noconfirm \
        vulkan-intel lib32-vulkan-intel intel-media-driver
    GPU_ENV_PROFILE="env-intel.conf"
    print_success "Intel drivers installed"
else
    print_info "VMware or Generic GPU detected — using fallback profile"
    GPU_ENV_PROFILE="env-vmware.conf"
    grep -q 'LIBGL_ALWAYS_SOFTWARE=1' /etc/environment 2>/dev/null || \
        echo 'LIBGL_ALWAYS_SOFTWARE=1' | sudo tee -a /etc/environment >/dev/null || true
fi

# Step 5: Install Caelestia Shell (Rice / Full only)
print_step "Step 5/8: Desktop Shell & Themes"
if [ "$INSTALL_RICE" = true ]; then
    AUR_PKGS=(caelestia-cli papirus-icon-theme catppuccin-gtk-theme-mocha bibata-cursor-theme-bin waypaper swww)
    for pkg in "${AUR_PKGS[@]}"; do
        pacman -Qi "$pkg" &>/dev/null && { print_info "$pkg already installed, skipping"; continue; }
        yay -S --noconfirm "$pkg" || print_warning "Failed to install $pkg"
    done
    print_info "Running Caelestia installer... (Recommended: select uwsm (8))"
    caelestia install || print_warning "Caelestia installer finished with notices"
    print_success "Caelestia Shell installed"
else
    print_info "Skipping Caelestia Shell for $INSTALL_MODE profile"
fi

# Step 6: Backup & Copy dotfiles
print_step "Step 6/8: Backing up & copying dotfiles"
mkdir -p ~/.config/{hypr,foot,fuzzel,fish,Thunar} ~/.local/bin

copy_with_backup "$DOTFILES_DIR/hypr/hyprland.conf" ~/.config/hypr/hyprland.conf
copy_with_backup "$DOTFILES_DIR/hypr/env.conf" ~/.config/hypr/env.conf
copy_with_backup "$DOTFILES_DIR/hypr/hypridle.conf" ~/.config/hypr/hypridle.conf

if [ -n "$GPU_ENV_PROFILE" ] && [ -f "$DOTFILES_DIR/hypr/$GPU_ENV_PROFILE" ]; then
    backup_config "$HOME/.config/hypr/env-gpu.conf"
    cp -v "$DOTFILES_DIR/hypr/$GPU_ENV_PROFILE" ~/.config/hypr/env-gpu.conf
    print_success "GPU profile applied: $GPU_ENV_PROFILE → env-gpu.conf"
fi

copy_with_backup "$DOTFILES_DIR/foot/foot.ini" ~/.config/foot/foot.ini
copy_with_backup "$DOTFILES_DIR/fuzzel/fuzzel.ini" ~/.config/fuzzel/fuzzel.ini
copy_with_backup "$DOTFILES_DIR/fish/config.fish" ~/.config/fish/config.fish
copy_with_backup "$DOTFILES_DIR/Thunar/uca.xml" ~/.config/Thunar/uca.xml

if [ "$INSTALL_RICE" = true ]; then
    mkdir -p ~/.config/{caelestia,mako,gtk-3.0,fastfetch,cava,waypaper} ~/Pictures/Wallpapers
    for f in caelestia/hypr-vars.lua caelestia/hypr-user.conf mako/config gtk-3.0/settings.ini fastfetch/config.jsonc cava/config waypaper/config.ini; do
        copy_with_backup "$DOTFILES_DIR/$f" "$HOME/.config/$f"
    done
    grep -q 'hypr-user\.conf' ~/.config/hypr/hyprland.conf 2>/dev/null || \
        echo 'source = ~/.config/caelestia/hypr-user.conf' >> ~/.config/hypr/hyprland.conf
fi

[ -d "$SCRIPTS_DIR" ] && { cp -v "$SCRIPTS_DIR/"* ~/.local/bin/ 2>/dev/null || true; chmod +x ~/.local/bin/*; }
print_success "Dotfiles copied (old configs backed up with .backup.* suffix)"

# Step 7: SDDM Theme (Rice / Full only)
print_step "Step 7/8: Setting up Display Manager (SDDM)"
if [ "$INSTALL_RICE" = true ]; then
    sudo pacman -S --needed --noconfirm sddm \
        qt6-multimedia-ffmpeg qt6-multimedia qt6-5compat qt6-declarative qt6-svg \
        qt5-graphicaleffects qt5-quickcontrols2 qt5-svg qt5-multimedia 2>/dev/null || true

    SDDM_TMP="/tmp/sddm-astronaut-theme-$$"
    SDDM_DEST="/usr/share/sddm/themes/sddm-astronaut-theme"
    if sudo git clone https://github.com/Keyitdev/sddm-astronaut-theme.git "$SDDM_TMP" 2>/dev/null; then
        sudo rm -rf "$SDDM_DEST" && sudo mv "$SDDM_TMP" "$SDDM_DEST"
        [ -f ~/Pictures/Wallpapers/emilia_dark.png ] && \
            sudo cp ~/Pictures/Wallpapers/emilia_dark.png "$SDDM_DEST/Backgrounds/emilia.png" 2>/dev/null || true
        sudo sed -i 's|^ConfigFile=.*|ConfigFile=Themes/pixel_sakura.conf|' "$SDDM_DEST/metadata.desktop" 2>/dev/null || true
        sudo sed -i 's/ScaleMode=.*/ScaleMode="Fill"/' "$SDDM_DEST/Themes/pixel_sakura.conf" 2>/dev/null || true
        sudo mkdir -p /etc/sddm.conf.d
        echo -e '[Theme]\nCurrent=sddm-astronaut-theme' | sudo tee /etc/sddm.conf.d/theme.conf >/dev/null
        print_success "SDDM Astronaut theme configured"
    else
        sudo rm -rf "$SDDM_TMP"
        print_warning "SDDM theme clone failed (network?). Existing theme preserved."
    fi
else
    print_info "Skipping SDDM theme for $INSTALL_MODE profile"
fi

# Step 8: Enable services & finalize
print_step "Step 8/8: Enabling services & finalizing"
for svc in NetworkManager bluetooth power-profiles-daemon; do
    sudo systemctl enable --now "$svc" 2>/dev/null || true
done
[ "$INSTALL_RICE" = true ] && sudo systemctl enable sddm 2>/dev/null || true

[ "${SHELL:-}" != "$(which fish)" ] && { chsh -s "$(which fish)"; print_success "Default shell changed to Fish"; }
xdg-user-dirs-update 2>/dev/null || true

if [ "$INSTALL_RICE" = true ] && [ ! -f ~/Pictures/Wallpapers/emilia_dark.png ]; then
    print_info "Downloading default wallpapers..."
    curl -sL -o ~/Pictures/Wallpapers/emilia_dark.png \
        "https://raw.githubusercontent.com/doki-theme/doki-theme-assets/master/backgrounds/wallpapers/emilia_dark.png" 2>/dev/null || true
fi
print_success "Services enabled"

# Done
echo -e "\n${PINK}  🌸 Installation Complete! 🌸${NC}\n"
echo -e "${CYAN}  Profile: ${PINK}$INSTALL_MODE${NC}"
echo -e "${CYAN}  GPU:     ${PINK}${GPU_ENV_PROFILE:-auto}${NC}\n"
echo -e "${CYAN}  Next steps:${NC}"
echo -e "${GREEN}  1. Log out and log back in (or reboot)${NC}"
[ "$INSTALL_RICE" = true ] && echo -e "${GREEN}  2. Set wallpaper: ${PINK}caelestia wallpaper -f ~/Pictures/Wallpapers/emilia_dark.png${NC}"
echo -e "${GREEN}  3. Run health check: ${PINK}./check.sh${NC}\n"
echo -e "${CYAN}  Key bindings:${NC}"
echo -e "${GREEN}  Super + T / Super + Return →  Terminal (Foot)"
echo -e "  Super + D / Alt + D        →  App Launcher"
echo -e "  Super + V / Alt + V        →  Clipboard History"
echo -e "  Super + N / Alt + N        →  Sidebar / Control Center"
echo -e "  Super + Q / Alt + Q        →  Close window"
echo -e "  Super + E / Alt + E        →  File manager (Thunar)"
echo -e "  Super + L                  →  Lock screen${NC}\n"
echo -e "${PURPLE}  Enjoy your Arch Linux + Hyprland setup! 🌸✨${NC}\n"
