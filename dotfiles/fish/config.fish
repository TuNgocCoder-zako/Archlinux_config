# Fish Shell — Caelestia Rice Config
set -g fish_greeting

if status is-interactive
    # Aliases
    alias ll="eza -la --icons 2>/dev/null; or ls -la"
    alias update="sudo pacman -Syyu"
    alias cls="clear"
    alias momoi="momoisay animate 2>/dev/null; or echo 'Install: cargo install momoisay'"
    alias dance="momoisay freestyle 2>/dev/null; or echo 'Install: cargo install momoisay'"

    # Set wallpaper shortcut
    alias wall="caelestia wallpaper -f"
    alias wallr="caelestia wallpaper -r ~/Pictures/Wallpapers"
end
