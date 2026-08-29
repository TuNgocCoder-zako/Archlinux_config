# ╔══════════════════════════════════════════════════╗
# ║  Fish Shell — Caelestia Anime Rice Config        ║
# ╚══════════════════════════════════════════════════╝

# Disable default greeting
set -g fish_greeting

# Add paths
fish_add_path ~/.cargo/bin /usr/local/bin

# Wayland display detection for SSH
set -gx WAYLAND_DISPLAY (ls /run/user/(id -u)/wayland-* 2>/dev/null | head -1 | xargs basename 2>/dev/null)
set -gx XDG_RUNTIME_DIR /run/user/(id -u)

# Aliases
alias ll="eza -la --icons 2>/dev/null; or ls -la"
alias update="sudo pacman -Syyu"
alias cls="clear"
alias fetch="fastfetch"
alias momoi="momoisay freestyle"
alias dance="momoisay animate"
alias wall="caelestia wallpaper -f"
alias wallr="caelestia wallpaper -r ~/Pictures/Wallpapers"

# Anime Momoisay Greeting
if type -q momoisay
    momoisay say "Hello Master! Welcome back!"
end
