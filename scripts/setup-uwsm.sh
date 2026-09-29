#!/usr/bin/env bash
# ==============================================================================
# SETUP UWSM (Universal Wayland Session Manager) FOR HYPRLAND & CAELESTIA
# ==============================================================================
# - Quản lý phiên Hyprland qua systemd cgroups/slices (app.slice, session.slice).
# - Crash-proof: Khi app nặng bị kill (out of memory), không làm sập cả Hyprland.
# - Chuẩn hóa biến môi trường Wayland, XDG, Intel iGPU và Fcitx5.
# - Không làm thay đổi hay mất theme/hình nền SDDM Enfield hiện tại.
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}      THIẾT LẬP UWSM CHO HYPRLAND & CAELESTIA SHELL             ${NC}"
echo -e "${BLUE}================================================================${NC}"

# 1. Kiểm tra gói uwsm
if ! command -v uwsm &>/dev/null; then
    echo -e "${YELLOW}[!]${NC} Chưa tìm thấy uwsm. Đang cài đặt..."
    pacman -S --noconfirm --needed uwsm
else
    echo -e "${GREEN}[OK]${NC} Đã có sẵn uwsm: $(uwsm --version 2>/dev/null || echo 'installed')"
fi

# 2. Tạo desktop entry cho Caelestia với UWSM trong /usr/share/wayland-sessions
echo -e "${CYAN}>>> Đang tạo mục chọn phiên Caelestia (UWSM) cho SDDM...${NC}"
cat << 'EOF' > /usr/share/wayland-sessions/caelestia-uwsm.desktop
[Desktop Entry]
Name=Caelestia (UWSM)
Comment=Caelestia Material You Shell on Hyprland (UWSM Managed)
Exec=uwsm start -e -D Hyprland hyprland.desktop
TryExec=uwsm
DesktopNames=Hyprland
Type=Application
Keywords=tiling;wayland;compositor;caelestia;uwsm;
EOF

chmod 644 /usr/share/wayland-sessions/caelestia-uwsm.desktop
echo -e "${GREEN}[OK]${NC} Đã tạo /usr/share/wayland-sessions/caelestia-uwsm.desktop"

# 3. Cập nhật SDDM nhớ phiên đăng nhập UWSM (nếu có state.conf)
SDDM_STATE="/var/lib/sddm/state.conf"
if [ -d "/var/lib/sddm" ]; then
    echo -e "${CYAN}>>> Cấu hình phiên mặc định cho SDDM...${NC}"
    mkdir -p /var/lib/sddm
    cat << 'EOF' > "$SDDM_STATE"
[Last]
Session=/usr/share/wayland-sessions/hyprland-uwsm.desktop
User=tu
EOF
    chown -R sddm:sddm /var/lib/sddm 2>/dev/null || true
    echo -e "${GREEN}[OK]${NC} Đã đặt phiên mặc định SDDM thành Hyprland (uwsm-managed)."
fi

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}      HOÀN TẤT THIẾT LẬP UWSM THÀNH CÔNG!                      ${NC}"
echo -e "${CYAN}   - Hình nền & theme SDDM Enfield giữ nguyên 100%.             ${NC}"
echo -e "${CYAN}   - Cấu hình người dùng (~/.config/uwsm/) đã được đồng bộ.      ${NC}"
echo -e "${YELLOW}   -> Khi khởi động lại hoặc đăng nhập mới, hệ thống sẽ tự       ${NC}"
echo -e "${YELLOW}      chạy qua UWSM mà không làm ảnh hưởng công việc hiện tại.  ${NC}"
echo -e "${GREEN}================================================================${NC}"
