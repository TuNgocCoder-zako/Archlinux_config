#!/bin/bash
# ╔══════════════════════════════════════════════════════════╗
# ║  Arch Linux + Hyprland + Caelestia Shell Installer       ║
# ║  Material You Dynamic Theming — Bare Metal Ready         ║
# ╚══════════════════════════════════════════════════════════╝

set -e

# Colors
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"
USER_HOME="$HOME"

print_banner

# === Safety checks ===
if [ "$EUID" -eq 0 ]; then
    print_warning "Do NOT run as root! Run as your normal user."
    exit 1
fi

echo -e "${PINK}This will install Arch Linux + Hyprland + Caelestia Shell.${NC}"
echo -e "${PINK}Designed for bare metal machines (also works on VMware).${NC}"
echo ""
read -p "Continue? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

# ────────────────────────────────────────────
# Step 1: System Update
# ────────────────────────────────────────────
print_step "Step 1/9: Updating system"
sudo pacman -Syu --noconfirm
print_success "System updated"

# ────────────────────────────────────────────
# Step 2: Install yay (AUR helper)
# ────────────────────────────────────────────
print_step "Step 2/9: Installing yay (AUR helper)"
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
# Step 3: Install base packages
# ────────────────────────────────────────────
print_step "Step 3/9: Installing base packages"

PACMAN_PKGS=(
    # Compositor
    hyprland
    polkit-gnome
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xdg-utils
    xdg-user-dirs

    # Terminal & Shell
    foot
    fish
    starship

    # Launcher & Notifications
    fuzzel
    mako
    libnotify

    # File Manager
    thunar
    thunar-archive-plugin
    gvfs
    tumbler
    shared-mime-info

    # Image Viewer
    viewnior

    # Audio
    pipewire
    wireplumber
    pipewire-pulse
    pipewire-alsa
    pipewire-jack
    pavucontrol
    playerctl

    # Network & Bluetooth
    networkmanager
    network-manager-applet
    bluez
    bluez-utils
    blueman

    # Screenshot & Clipboard
    grim
    slurp
    wl-clipboard
    cliphist
    swappy

    # Lock & Idle
    hyprlock
    hypridle

    # Brightness
    brightnessctl

    # Theming
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

    # System Info & Visualizer
    fastfetch
    cava

    # Browser
    firefox

    # Power management
    power-profiles-daemon
    upower

    # Utilities
    unzip wget curl jq git ripgrep bat eza
    python python-pillow pybind11
    rust cargo
    ethtool
)

sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
print_success "Base packages installed"

# ────────────────────────────────────────────
# Step 4: Install Caelestia Shell via AUR
# ────────────────────────────────────────────
print_step "Step 4/9: Installing Caelestia Shell (AUR)"

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
print_success "AUR packages installed"

# ────────────────────────────────────────────
# Step 5: Run Caelestia installer
# ────────────────────────────────────────────
print_step "Step 5/9: Running Caelestia installer"
print_info "This will install Quickshell, Caelestia Shell, and all widgets."
print_info "When prompted for components, select what you need."
print_info "Recommended: uwsm (8) for basic setup."
echo ""
caelestia install
print_success "Caelestia Shell installed"

# ────────────────────────────────────────────
# Step 6: Copy custom dotfiles
# ────────────────────────────────────────────
print_step "Step 6/9: Copying custom dotfiles"

# Create directories
mkdir -p ~/.config/{caelestia,hypr,foot,fuzzel,mako,gtk-3.0,fastfetch,cava,fish,Thunar}
mkdir -p ~/.local/bin
mkdir -p ~/Pictures/Wallpapers

# Caelestia overrides
[ -f "$DOTFILES_DIR/caelestia/hypr-vars.lua" ] && cp -v "$DOTFILES_DIR/caelestia/hypr-vars.lua" ~/.config/caelestia/
[ -f "$DOTFILES_DIR/caelestia/hypr-user.conf" ] && cp -v "$DOTFILES_DIR/caelestia/hypr-user.conf" ~/.config/caelestia/

# Hyprland configs (idle, env)
[ -f "$DOTFILES_DIR/hypr/env.conf" ] && cp -v "$DOTFILES_DIR/hypr/env.conf" ~/.config/hypr/
[ -f "$DOTFILES_DIR/hypr/hypridle.conf" ] && cp -v "$DOTFILES_DIR/hypr/hypridle.conf" ~/.config/hypr/

# Terminal
[ -f "$DOTFILES_DIR/foot/foot.ini" ] && cp -v "$DOTFILES_DIR/foot/foot.ini" ~/.config/foot/

# Launcher
[ -f "$DOTFILES_DIR/fuzzel/fuzzel.ini" ] && cp -v "$DOTFILES_DIR/fuzzel/fuzzel.ini" ~/.config/fuzzel/

# Notifications (fallback)
[ -f "$DOTFILES_DIR/mako/config" ] && cp -v "$DOTFILES_DIR/mako/config" ~/.config/mako/

# GTK
[ -f "$DOTFILES_DIR/gtk-3.0/settings.ini" ] && cp -v "$DOTFILES_DIR/gtk-3.0/settings.ini" ~/.config/gtk-3.0/

# Fastfetch
[ -f "$DOTFILES_DIR/fastfetch/config.jsonc" ] && cp -v "$DOTFILES_DIR/fastfetch/config.jsonc" ~/.config/fastfetch/

# Cava
[ -f "$DOTFILES_DIR/cava/config" ] && cp -v "$DOTFILES_DIR/cava/config" ~/.config/cava/

# Fish shell
[ -f "$DOTFILES_DIR/fish/config.fish" ] && cp -v "$DOTFILES_DIR/fish/config.fish" ~/.config/fish/

# Thunar custom actions
[ -f "$DOTFILES_DIR/Thunar/uca.xml" ] && cp -v "$DOTFILES_DIR/Thunar/uca.xml" ~/.config/Thunar/

# Scripts
if [ -d "$SCRIPTS_DIR" ]; then
    cp -v "$SCRIPTS_DIR/"* ~/.local/bin/ 2>/dev/null
    chmod +x ~/.local/bin/*
fi

print_success "Dotfiles copied"

# ────────────────────────────────────────────
# Step 7: Install bonus tools
# ────────────────────────────────────────────
print_step "Step 7/9: Installing bonus tools (Momoisay)"

if command -v cargo &> /dev/null; then
    cargo install momoisay 2>/dev/null && \
        sudo ln -sf ~/.cargo/bin/momoisay /usr/local/bin/momoisay && \
        print_success "momoisay installed" || \
        print_warning "momoisay installation failed (optional)"
else
    print_warning "Rust/Cargo not found, skipping momoisay"
fi

# ────────────────────────────────────────────
# Step 8: Download wallpapers
# ────────────────────────────────────────────
print_step "Step 8/9: Downloading anime wallpapers"

mkdir -p ~/Pictures/Wallpapers
curl -L -o ~/Pictures/Wallpapers/emilia_dark.png \
    "https://raw.githubusercontent.com/doki-theme/doki-theme-assets/master/backgrounds/wallpapers/emilia_dark.png" 2>/dev/null && \
    print_success "Downloaded: emilia_dark.png" || print_warning "Failed to download emilia_dark.png"

curl -L -o ~/Pictures/Wallpapers/emilia_light.png \
    "https://raw.githubusercontent.com/doki-theme/doki-theme-assets/master/backgrounds/wallpapers/emilia_light.png" 2>/dev/null && \
    print_success "Downloaded: emilia_light.png" || print_warning "Failed to download emilia_light.png"

curl -L -o ~/Pictures/Wallpapers/beatrice.png \
    "https://raw.githubusercontent.com/doki-theme/doki-theme-assets/master/backgrounds/wallpapers/beatrice.png" 2>/dev/null && \
    print_success "Downloaded: beatrice.png" || print_warning "Failed to download beatrice.png"

print_success "Wallpapers downloaded"

# ────────────────────────────────────────────
# Step 9: Configure SDDM Login Theme
# ────────────────────────────────────────────
print_step "Step 9/10: Setting up SDDM Catppuccin Theme"

sudo pacman -S --needed --noconfirm sddm qt5-graphicaleffects qt5-quickcontrols2 qt5-svg qt6-svg qt6-declarative 2>/dev/null || true

curl -L -o /tmp/catppuccin-mocha.zip "https://github.com/catppuccin/sddm/releases/download/v1.1.2/catppuccin-mocha-mauve-sddm.zip" 2>/dev/null && \
    sudo unzip -o /tmp/catppuccin-mocha.zip -d /usr/share/sddm/themes/ && \
    rm -f /tmp/catppuccin-mocha.zip && \
    sudo rm -rf /usr/share/sddm/themes/catppuccin-mocha && \
    sudo mv /usr/share/sddm/themes/catppuccin-mocha-mauve /usr/share/sddm/themes/catppuccin-mocha && \
    sudo cp ~/Pictures/Wallpapers/emilia_dark.png /usr/share/sddm/themes/catppuccin-mocha/backgrounds/emilia.png 2>/dev/null && \
    sudo sed -i 's/Background=.*/Background="backgrounds\/emilia.png"/' /usr/share/sddm/themes/catppuccin-mocha/theme.conf && \
    sudo mkdir -p /etc/sddm.conf.d && \
    sudo bash -c 'cat << "EOF" > /etc/sddm.conf.d/theme.conf
[Theme]
Current=catppuccin-mocha
EOF' && \
    print_success "SDDM Catppuccin theme configured" || print_warning "SDDM theme setup skipped"

# ────────────────────────────────────────────
# Step 10: Enable services
# ────────────────────────────────────────────
print_step "Step 10/10: Enabling system services"

sudo systemctl enable --now NetworkManager 2>/dev/null || true
sudo systemctl enable --now bluetooth 2>/dev/null || true
sudo systemctl enable --now power-profiles-daemon 2>/dev/null || true
sudo systemctl enable sddm 2>/dev/null || true

# Set Fish as default shell
if [ "$SHELL" != "$(which fish)" ]; then
    chsh -s "$(which fish)"
    print_success "Default shell changed to Fish"
fi

# Create user directories
xdg-user-dirs-update 2>/dev/null || true

print_success "Services enabled"

# ────────────────────────────────────────────
# Done!
# ────────────────────────────────────────────
echo ""
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${PINK}"
echo "  ╔═══════════════════════════════════════════════╗"
echo "  ║                                               ║"
echo "  ║   🌸 Installation Complete! 🌸               ║"
echo "  ║                                               ║"
echo "  ╚═══════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${CYAN}  Next steps:${NC}"
echo -e "${GREEN}  1. Log out and log back in${NC}"
echo -e "${GREEN}  2. From TTY, run: ${PINK}start-hyprland${GREEN} (or Hyprland)${NC}"
echo -e "${GREEN}  3. Set wallpaper: ${PINK}caelestia wallpaper -f ~/Pictures/Wallpapers/emilia_dark.png${NC}"
echo ""
echo -e "${CYAN}  Caelestia key bindings:${NC}"
echo -e "${GREEN}  Super + T          →  Terminal (Foot)${NC}"
echo -e "${GREEN}  Super (tap)        →  App Launcher${NC}"
echo -e "${GREEN}  Super + N          →  Sidebar / Control Center${NC}"
echo -e "${GREEN}  Super + Q          →  Close window${NC}"
echo -e "${GREEN}  Super + E          →  File manager (Thunar)${NC}"
echo -e "${GREEN}  Super + L          →  Lock screen${NC}"
echo -e "${GREEN}  Super + Shift + Q  →  Exit Hyprland${NC}"
echo ""
echo -e "${PURPLE}  Enjoy your Caelestia Shell rice! 🌸✨${NC}"
echo -e "${PINK}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
