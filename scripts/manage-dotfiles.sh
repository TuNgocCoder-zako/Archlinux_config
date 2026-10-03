#!/usr/bin/env bash
# ==============================================================================
# MANAGE DOTFILES WITH GNU STOW (Arch Linux + Hyprland + Caelestia)
# ==============================================================================
# - Quản lý liên kết động (Symlinks 2 chiều) giữa repo Git và ~/.config/
# - Tự động sao lưu file cũ trước khi stow để đảm bảo an toàn 100%
# - Hỗ trợ các lệnh: stow, restow, unstow, status, diff
# ==============================================================================

set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOTFILES_DIR="$REPO_ROOT/dotfiles"
CONFIG_DIR="$HOME/.config"
STOW_BIN="$HOME/.local/bin/stow"

if ! command -v "$STOW_BIN" &>/dev/null && ! command -v stow &>/dev/null; then
    echo -e "${RED}[LỖI]${NC} Không tìm thấy lệnh stow. Đang kiểm tra lại..."
    exit 1
fi
STOW_CMD="${STOW_BIN:-stow}"

# Danh sách các gói dotfiles thuộc ~/.config
CONFIG_PACKAGES=(
    "hypr"
    "kitty"
    "caelestia"
    "uwsm"
    "fish"
    "fuzzel"
    "cava"
    "mako"
    "fastfetch"
    "foot"
    "gtk-3.0"
    "Thunar"
    "quickshell"
    "nwg-dock-hyprland"
)

backup_and_stow_pkg() {
    local pkg="$1"
    local src_dir="$DOTFILES_DIR/$pkg"
    local tgt_dir="$CONFIG_DIR/$pkg"

    if [ ! -d "$src_dir" ]; then
        echo -e "${YELLOW}[!]${NC} Bỏ qua: Gói '$pkg' không tồn tại trong $DOTFILES_DIR"
        return
    fi

    mkdir -p "$tgt_dir"

    # Sao lưu các file thường (không phải symlink) có nguy cơ xung đột
    local backup_root="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)/$pkg"
    local backed_up=0

    while IFS= read -r -d '' rel_file; do
        local target_file="$tgt_dir/$rel_file"
        if [ -e "$target_file" ] && [ ! -L "$target_file" ]; then
            mkdir -p "$(dirname "$backup_root/$rel_file")"
            mv "$target_file" "$backup_root/$rel_file"
            backed_up=$((backed_up + 1))
        fi
    done < <(cd "$src_dir" && find . -type f -print0)

    if [ "$backed_up" -gt 0 ]; then
        echo -e "${BLUE}  ℹ Đã sao lưu $backed_up file cũ vào: $backup_root${NC}"
    fi

    # Thực hiện GNU Stow
    "$STOW_CMD" -d "$DOTFILES_DIR" -t "$tgt_dir" "$pkg"
    echo -e "${GREEN}  ✔ Đã liên kết module '$pkg' -> $tgt_dir${NC}"
}

unstow_pkg() {
    local pkg="$1"
    local tgt_dir="$CONFIG_DIR/$pkg"

    if [ -d "$DOTFILES_DIR/$pkg" ]; then
        "$STOW_CMD" -D -d "$DOTFILES_DIR" -t "$tgt_dir" "$pkg" 2>/dev/null || true
        echo -e "${YELLOW}  ✔ Đã gỡ liên kết module '$pkg'${NC}"
    fi
}

check_status() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${CYAN}          TRẠNG THÁI LIÊN KẾT DOTFILES (GNU STOW)               ${NC}"
    echo -e "${BLUE}================================================================${NC}"
    printf "%-15s %-12s %-30s\n" "Module" "Trạng thái" "Đường dẫn ~/.config/"
    echo "----------------------------------------------------------------"

    for pkg in "${CONFIG_PACKAGES[@]}"; do
        local tgt_dir="$CONFIG_DIR/$pkg"
        if [ ! -d "$tgt_dir" ]; then
            printf "%-15s ${YELLOW}%-12s${NC} %-30s\n" "$pkg" "Chưa có" "$tgt_dir"
            continue
        fi

        # Kiểm tra xem có symlink trỏ về repo không
        local link_count
        link_count=$(find "$tgt_dir" -maxdepth 2 -type l -lname "*Archlinux_config*" 2>/dev/null | wc -l)
        if [ "$link_count" -gt 0 ]; then
            printf "%-15s ${GREEN}%-12s${NC} %-30s (%d links)\n" "$pkg" "Đã Stow" "$tgt_dir" "$link_count"
        else
            printf "%-15s ${RED}%-12s${NC} %-30s (File thường)\n" "$pkg" "Chưa Stow" "$tgt_dir"
        fi
    done
    echo -e "${BLUE}================================================================${NC}"
}

cmd="${1:-status}"

case "$cmd" in
    stow|apply)
        target_pkg="${2:-all}"
        echo -e "${CYAN}>>> Đang kích hoạt GNU Stow cho dotfiles...${NC}"
        if [ "$target_pkg" = "all" ]; then
            for p in "${CONFIG_PACKAGES[@]}"; do
                backup_and_stow_pkg "$p"
            done
        else
            backup_and_stow_pkg "$target_pkg"
        fi
        echo -e "${GREEN}[OK] Hoàn tất quá trình liên kết Stow!${NC}"
        ;;
    unstow|remove)
        target_pkg="${2:-all}"
        echo -e "${YELLOW}>>> Đang gỡ bỏ liên kết Stow...${NC}"
        if [ "$target_pkg" = "all" ]; then
            for p in "${CONFIG_PACKAGES[@]}"; do
                unstow_pkg "$p"
            done
        else
            unstow_pkg "$target_pkg"
        fi
        echo -e "${GREEN}[OK] Hoàn tất gỡ bỏ liên kết!${NC}"
        ;;
    restow)
        target_pkg="${2:-all}"
        echo -e "${CYAN}>>> Đang tái tạo (Restow) liên kết...${NC}"
        "$0" unstow "$target_pkg"
        "$0" stow "$target_pkg"
        if command -v hyprctl &>/dev/null; then
            hyprctl seterror disable &>/dev/null || true
            hyprctl reload &>/dev/null || true
        fi
        ;;
    status)
        check_status
        ;;
    diff)
        git -C "$REPO_ROOT" diff
        ;;
    *)
        echo "Sử dụng: $0 [stow|unstow|restow|status|diff] [module|all]"
        exit 1
        ;;
esac
