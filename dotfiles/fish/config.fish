# Fish Shell — Caelestia Anime Rice Config

set -g fish_greeting
fish_add_path ~/.cargo/bin ~/.local/bin /usr/local/bin

alias ll="eza -la --icons 2>/dev/null; or ls -la"
alias update="sudo pacman -Syu"
alias cls="clear"
alias fetch="fastfetch"
alias momoi="momoisay freestyle"
alias dance="momoisay animate"
alias wall="~/.local/bin/set-wallpaper"
alias wallr='~/.local/bin/set-wallpaper (find ~/Pictures/Wallpapers/ -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | shuf -n 1)'

if status is-interactive; and status is-login; and type -q momoisay
    momoisay say "Hello Master! Welcome back!"
end
