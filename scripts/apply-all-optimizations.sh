#!/usr/bin/env bash
# ==============================================================================
# MASTER RUNNER: Áp dụng toàn bộ gói nâng cấp hệ thống Arch Linux tối ưu nhất
# - Tự động thực thi tuần tự các phân hệ mà không cần người dùng chọn lựa:
#   1. Tối ưu thời gian khởi động (GRUB, Docker socket, Early KMS i915)
#   2. Thiết lập cơ chế Snapshot & Rollback tự động trước khi pacman update
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[LỖI]${NC} Vui lòng chạy script này với quyền root: sudo $0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}   KHỞI ĐỘNG CHƯƠNG TRÌNH NÂNG CẤP TOÀN DIỆN ARCH LINUX        ${NC}"
echo -e "${BLUE}================================================================${NC}"

# Chạy phân hệ 1: Tối ưu Boot Time & Docker
echo -e "\n${CYAN}>>> ĐANG CHẠY PHÂN HỆ 1/5: BOOT SPEED & DOCKER OPTIMIZATION...${NC}"
bash "$SCRIPT_DIR/setup-boot-optimization.sh"

# Chạy phân hệ 2: Thiết lập Snapshot & Rollback
echo -e "\n${CYAN}>>> ĐANG CHẠY PHÂN HỆ 2/5: AUTOMATED SNAPSHOT & ROLLBACK...${NC}"
bash "$SCRIPT_DIR/setup-system-snapshot.sh"

# Chạy phân hệ 3: Tích hợp UWSM cho Hyprland
echo -e "\n${CYAN}>>> ĐANG CHẠY PHÂN HỆ 3/5: UWSM SESSION MANAGER...${NC}"
bash "$SCRIPT_DIR/setup-uwsm.sh"

# Chạy phân hệ 4: Cài đặt quy tắc phần cứng & Daemon
echo -e "\n${CYAN}>>> ĐANG CHẠY PHÂN HỆ 4/5: SYSTEM RULES & POWER PROFILES...${NC}"
bash "$REPO_ROOT/system/setup-system-rules.sh"

# Chạy phân hệ 5: Tối ưu hiển thị & Chống giật lag GPU
echo -e "\n${CYAN}>>> ĐANG CHẠY PHÂN HỆ 5/5: DISPLAY SMOOTHNESS & GPU CLOCKS...${NC}"
bash "$SCRIPT_DIR/setup-display-smoothness.sh"

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}   TẤT CẢ CÁC NÂNG CẤP ĐÃ ĐƯỢC ÁP DỤNG THÀNH CÔNG RỰC RỠ!       ${NC}"
echo -e "${CYAN}   - Boot time đã giảm tối đa (Bootloader 1s, Docker on-demand).${NC}"
echo -e "${CYAN}   - Hệ thống được bảo vệ 100% bởi Timeshift Snapshot tự động. ${NC}"
echo -e "${CYAN}   - Phiên Hyprland được quản lý chuẩn xác bởi UWSM (Cgroups).  ${NC}"
echo -e "${CYAN}   - Hệ thống tối ưu hóa GPU Intel TigerLake & ananicy rules.   ${NC}"
echo -e "${YELLOW}   -> Bạn có thể reboot máy bất kỳ lúc nào để cảm nhận độ mượt! ${NC}"
echo -e "${GREEN}================================================================${NC}"
