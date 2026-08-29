# ╔══════════════════════════════════════════════════╗
# ║  Fish Shell — Caelestia Anime Rice Config        ║
# ╚══════════════════════════════════════════════════╝

# Tắt lời chào mặc định
set -g fish_greeting

# Thiết lập biến môi trường Wayland tự động cho SSH
set -gx WAYLAND_DISPLAY (ls /run/user/(id -u)/wayland-* 2>/dev/null | head -1 | xargs basename 2>/dev/null)
set -gx XDG_RUNTIME_DIR /run/user/(id -u)

if status is-interactive
    # ── Aliases tiện ích ──
    alias ll="eza -la --icons 2>/dev/null; or ls -la"
    alias update="sudo pacman -Syyu"
    alias cls="clear"
    alias fetch="fastfetch"
    alias momoi="momoisay freestyle 2>/dev/null; or echo 'Chạy: cargo install momoisay'"
    alias dance="momoisay animate 2>/dev/null; or echo 'Chạy: cargo install momoisay'"

    # Đổi hình nền nhanh với Caelestia
    alias wall="caelestia wallpaper -f"
    alias wallr="caelestia wallpaper -r ~/Pictures/Wallpapers"

    # ── Lời chào Momoisay khi mở Terminal mới ──
    if type -q momoisay
        momoisay say "Chào Master! Chúc một ngày tốt lành ✿"
    end
end
