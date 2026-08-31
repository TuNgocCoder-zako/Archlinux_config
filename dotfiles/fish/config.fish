# ╔══════════════════════════════════════════════════╗
# ║  Fish Shell — Caelestia Anime Rice Config        ║
# ╚══════════════════════════════════════════════════╝

# Disable default greeting
set -g fish_greeting

# Add paths
fish_add_path ~/.cargo/bin ~/.local/bin /usr/local/bin

# Aliases
alias ll="eza -la --icons 2>/dev/null; or ls -la"
alias update="sudo pacman -Syu"
alias cls="clear"
alias fetch="fastfetch"
alias momoi="momoisay freestyle"
alias dance="momoisay animate"
alias wall="~/.local/bin/set-wallpaper"
alias wallr='~/.local/bin/set-wallpaper (find ~/Pictures/Wallpapers/ -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | shuf -n 1)'

# Anime Momoisay Greeting (only in interactive login shell, not subshells/SSH)
if status is-interactive; and status is-login; and type -q momoisay
    momoisay say "Hello Master! Welcome back!"
end
