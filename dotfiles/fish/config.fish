# Fish Shell — Caelestia Anime Rice Config

set -g fish_greeting
fish_add_path ~/.cargo/bin ~/.local/bin /usr/local/bin ~/.config/composer/vendor/bin ~/src/flutter/bin ~/Android/Sdk/platform-tools ~/Android/Sdk/cmdline-tools/latest/bin

# Input method (Fcitx5 / Tiếng Việt)
set -gx XMODIFIERS '@im=fcitx'
set -gx QT_IM_MODULE 'fcitx'
set -gx SDL_IM_MODULE 'fcitx'
set -gx GLFW_IM_MODULE 'ibus'

# Caelestia Dynamic Terminal Colours
if status is-interactive
    cat ~/.local/state/caelestia/sequences.txt 2>/dev/null

    # Đồng bộ màu đường dẫn thư mục Tide theo màu chủ đạo của hình nền (Material You)
    function _tide_on_caelestia_color_change --on-variable tide_pwd_color_anchors
        source ~/.config/fish/functions/_tide_pwd.fish 2>/dev/null
    end

    if test -f ~/.local/state/caelestia/theme/fish_colors.fish
        source ~/.local/state/caelestia/theme/fish_colors.fish
    end

    # Hiển thị ảnh meme khi mở terminal (tự trôi khi gõ lệnh)
    if set -q KITTY_WINDOW_ID
        convert /home/tu/Pictures/Meme/4a5e3a42207397e1e66a471f75b9045d.jpg -resize 250x250 png:- 2>/dev/null | kitten icat --align left 2>/dev/null
        printf '\n'
    end

    # Cho phép Ctrl+V paste văn bản bình thường trong Fish shell
    bind \cv fish_clipboard_paste
end

alias ll="eza -la --icons 2>/dev/null; or ls -la"
alias update="sudo pacman -Syu"
alias cls="clear"
alias fetch="fastfetch"
alias wall="~/.local/bin/set-wallpaper"
alias wallr='~/.local/bin/set-wallpaper (find ~/Pictures/Wallpapers/ -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | shuf -n 1)'
alias agy="agy --dangerously-skip-permissions"
alias battery="~/.local/bin/battery"
alias batery="~/.local/bin/battery"
alias pin="~/.local/bin/battery"
alias bat="~/.local/bin/battery"


# Auto-start Hyprland when logging in on TTY1 (fallback if no Display Manager)
if status is-login
    if test -z "$DISPLAY" -a -z "$WAYLAND_DISPLAY" -a (tty) = "/dev/tty1"
        exec start-hyprland
    end
end

set -gx PHP_INI_SCAN_DIR ":/home/tu/.config/php"
