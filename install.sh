#!/bin/bash
# ╔══════════════════════════════════════════════════╗
# ║  Arch Linux + Hyprland Anime Rice Installer      ║
# ║  Catppuccin Mocha Theme — VMware Optimized       ║
# ╚══════════════════════════════════════════════════╝
#
# Usage:
#   chmod +x install.sh
#   ./install.sh
#
# This script will:
#   1. Install yay (AUR helper)
#   2. Install all required packages
#   3. Copy dotfiles to ~/.config/
#   4. Enable required services
#   5. Set up zsh as default shell

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
PINK='\033[1;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${PINK}"
    echo "  ╔═══════════════════════════════════════════╗"
    echo "  ║                                           ║"
    echo "  ║   🌸 Anime Hyprland Rice Installer 🌸    ║"
    echo "  ║   Catppuccin Mocha — VMware Edition       ║"
    echo "  ║                                           ║"
    echo "  ╚═══════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo -e "\n${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  ❯ $1${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}  ✔ $1${NC}"
}

print_warning() {
    echo -e "${RED}  ⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}  ℹ $1${NC}"
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

print_banner

# === Check if running as root ===
if [ "$EUID" -eq 0 ]; then
    print_warning "Do NOT run this script as root! Run as your normal user."
    exit 1
fi

# === Confirm ===
echo -e "${PINK}This script will install Hyprland + anime rice on Arch Linux.${NC}"
echo -e "${PINK}Designed for VMware Workstation VMs.${NC}"
echo ""
read -p "Continue? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

# ────────────────────────────────────────────
# Step 1: System Update
# ────────────────────────────────────────────
print_step "Step 1/8: Updating system"
sudo pacman -Syu --noconfirm
print_success "System updated"

# ────────────────────────────────────────────
# Step 2: Install yay (AUR helper)
# ────────────────────────────────────────────
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

# ────────────────────────────────────────────
# Step 3: Install VMware tools
# ────────────────────────────────────────────
print_step "Step 3/8: Installing VMware tools + GPU drivers"
sudo pacman -S --needed --noconfirm \
    open-vm-tools \
    mesa \
    xf86-video-vmware

sudo systemctl enable --now vmtoolsd.service
sudo systemctl enable --now vmware-vmblock-fuse.service 2>/dev/null || true
print_success "VMware tools installed and enabled"

# ────────────────────────────────────────────
# Step 4: Install all packages from pacman
# ────────────────────────────────────────────
print_step "Step 4/8: Installing packages from pacman"

PACMAN_PKGS=(
    # Compositor + seat
    hyprland
    seatd
    polkit-gnome

    # Bar + terminal + launcher
    waybar
    foot
    rofi-wayland

    # Notification
    swaync

    # Wallpaper
    swww

    # Lock + idle
    hyprlock
    hypridle

    # Audio
    pipewire
    wireplumber
    pipewire-pulse
    pipewire-alsa

    # Network + Bluetooth
    networkmanager
    network-manager-applet
    blueman

    # Screenshot + clipboard
    grim
    slurp
    wl-clipboard
    cliphist

    # Utils
    brightnessctl
    playerctl
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xdg-utils
    xdg-user-dirs

    # File manager
    thunar
    thunar-archive-plugin

    # Theming tools
    nwg-look
    qt5ct
    qt6ct
    kvantum

    # Fonts
    ttf-jetbrains-mono-nerd
    ttf-font-awesome
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji

    # Shell + prompt
    starship
    zsh

    # System info
    fastfetch

    # Audio GUI
    pavucontrol

    # Dependencies
    unzip
    wget
    curl
    jq
)

sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
print_success "Pacman packages installed"

# ────────────────────────────────────────────
# Step 5: Install AUR packages
# ────────────────────────────────────────────
print_step "Step 5/8: Installing AUR packages"

AUR_PKGS=(
    catppuccin-gtk-theme-mocha
    bibata-cursor-theme-bin
    papirus-icon-theme-git
    cava
    waypaper
)

for pkg in "${AUR_PKGS[@]}"; do
    if pacman -Qi "$pkg" &> /dev/null; then
        print_info "$pkg already installed, skipping"
    else
        yay -S --noconfirm "$pkg" || print_warning "Failed to install $pkg — you can install it manually later"
    fi
done
print_success "AUR packages installed"

# ────────────────────────────────────────────
# Step 6: Enable services
# ────────────────────────────────────────────
print_step "Step 6/8: Enabling system services"

sudo systemctl enable --now seatd
sudo usermod -a -G seat "$USER" 2>/dev/null || true
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth 2>/dev/null || true

print_success "Services enabled"
print_info "User '$USER' added to 'seat' group"

# ────────────────────────────────────────────
# Step 7: Copy dotfiles
# ────────────────────────────────────────────
print_step "Step 7/8: Copying dotfiles to ~/.config/"

# Create directories
mkdir -p ~/.config/{hypr,waybar,foot,rofi,swaync,gtk-3.0,gtk-4.0,fastfetch,cava,starship}
mkdir -p ~/Pictures/Wallpapers

# Copy dotfiles
if [ -d "$DOTFILES_DIR" ]; then
    # Hyprland
    cp -v "$DOTFILES_DIR/hypr/hyprland.conf" ~/.config/hypr/
    cp -v "$DOTFILES_DIR/hypr/env.conf" ~/.config/hypr/
    cp -v "$DOTFILES_DIR/hypr/keybinds.conf" ~/.config/hypr/
    cp -v "$DOTFILES_DIR/hypr/hyprlock.conf" ~/.config/hypr/
    cp -v "$DOTFILES_DIR/hypr/hypridle.conf" ~/.config/hypr/

    # Waybar
    cp -v "$DOTFILES_DIR/waybar/config.jsonc" ~/.config/waybar/
    cp -v "$DOTFILES_DIR/waybar/style.css" ~/.config/waybar/

    # Foot
    cp -v "$DOTFILES_DIR/foot/foot.ini" ~/.config/foot/

    # Rofi
    cp -v "$DOTFILES_DIR/rofi/anime.rasi" ~/.config/rofi/

    # swaync
    cp -v "$DOTFILES_DIR/swaync/config.json" ~/.config/swaync/
    cp -v "$DOTFILES_DIR/swaync/style.css" ~/.config/swaync/

    # GTK
    cp -v "$DOTFILES_DIR/gtk-3.0/settings.ini" ~/.config/gtk-3.0/

    # Starship
    cp -v "$DOTFILES_DIR/starship.toml" ~/.config/starship.toml

    # Fastfetch
    cp -v "$DOTFILES_DIR/fastfetch/config.jsonc" ~/.config/fastfetch/

    # Cava
    cp -v "$DOTFILES_DIR/cava/config" ~/.config/cava/

    # Zsh
    cp -v "$DOTFILES_DIR/.zshrc" ~/

    print_success "Dotfiles copied"
else
    print_warning "Dotfiles directory not found at $DOTFILES_DIR"
    print_warning "Make sure the 'dotfiles' folder is next to this script"
fi

# ────────────────────────────────────────────
# Step 8: Set zsh as default shell
# ────────────────────────────────────────────
print_step "Step 8/8: Setting zsh as default shell"

if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
    print_success "Default shell changed to zsh"
    print_info "Log out and back in for the change to take effect"
else
    print_info "zsh is already the default shell"
fi

# Create user directories
xdg-user-dirs-update 2>/dev/null || true

# ────────────────────────────────────────────
# Done!
# ────────────────────────────────────────────
echo ""
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PINK}"
echo "  ╔═══════════════════════════════════════════╗"
echo "  ║                                           ║"
echo "  ║   🌸 Installation Complete! 🌸            ║"
echo "  ║                                           ║"
echo "  ╚═══════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${CYAN}  Next steps:${NC}"
echo -e "${GREEN}  1. Download anime wallpapers to ~/Pictures/Wallpapers/${NC}"
echo -e "${GREEN}  2. Log out and log back in (for seat group + zsh)${NC}"
echo -e "${GREEN}  3. From TTY, run: ${PINK}Hyprland${NC}"
echo ""
echo -e "${CYAN}  Key bindings:${NC}"
echo -e "${GREEN}  Super + Enter    →  Terminal (foot)${NC}"
echo -e "${GREEN}  Super + D        →  App launcher (rofi)${NC}"
echo -e "${GREEN}  Super + Q        →  Close window${NC}"
echo -e "${GREEN}  Super + E        →  File manager${NC}"
echo -e "${GREEN}  Super + W        →  Wallpaper picker${NC}"
echo -e "${GREEN}  Super + Shift+Q  →  Exit Hyprland${NC}"
echo ""
echo -e "${PURPLE}  Optional: Install SDDM login manager:${NC}"
echo -e "${BLUE}  sudo pacman -S sddm${NC}"
echo -e "${BLUE}  yay -S sddm-theme-catppuccin${NC}"
echo -e "${BLUE}  sudo systemctl enable sddm${NC}"
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
