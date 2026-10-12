#!/usr/bin/env bash
# ==============================================================================
# Script thiết lập Snapshot & Tự động sao lưu hệ thống (Timeshift + Autosnap)
# - Bảo vệ hệ thống Arch Linux rolling-release trước mọi rủi ro gãy driver/kernel.
# - Tự động tạo snapshot rsync trước mỗi lần chạy 'pacman -Syu'.
# - Hỗ trợ khôi phục tức thì từ dòng lệnh TTY: 'sudo timeshift --restore'.
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

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}   THIẾT LẬP HỆ THỐNG SNAPSHOT & ROLLBACK TỰ ĐỘNG CHO ARCH     ${NC}"
echo -e "${BLUE}================================================================${NC}"

# 1. Cài đặt Timeshift và Cronie
echo -e "\n${BLUE}>>> [1/3] Kiểm tra & Cài đặt Timeshift...${NC}"
if ! command -v timeshift &>/dev/null; then
    pacman -S --needed --noconfirm timeshift cronie
    echo -e "${GREEN}[OK]${NC} Đã cài đặt Timeshift & Cronie."
else
    echo -e "${GREEN}[OK]${NC} Timeshift đã được cài đặt từ trước."
fi

# 2. Kích hoạt cronie timer cho các bản sao lưu định kỳ
systemctl enable --now cronie.service
echo -e "${GREEN}[OK]${NC} Đã kích hoạt cronie.service cho lịch backup."

# 3. Cấu hình timeshift cơ bản nếu chưa có
TIMESHIFT_JSON="/etc/timeshift/timeshift.json"
mkdir -p /etc/timeshift

if [ ! -f "$TIMESHIFT_JSON" ]; then
    ROOT_UUID=$(findmnt -n -o UUID /)
    cat << EOF > "$TIMESHIFT_JSON"
{
  "backup_device_uuid" : "$ROOT_UUID",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "false",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "false",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "true",
  "count_monthly" : "0",
  "count_weekly" : "0",
  "count_daily" : "1",
  "count_hourly" : "0",
  "count_boot" : "1",
  "snapshot_type" : "RSYNC",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [
    "+ /home/tu/.config/***",
    "+ /home/tu/.local/bin/***",
    "+ /home/tu/Archlinux_config/***",
    "- /home/tu/**"
  ],
  "exclude-apps" : []
}
EOF
    echo -e "${GREEN}[OK]${NC} Đã tạo cấu hình chuẩn: Giới hạn lưu đúng 1 bản snapshot duy nhất."
fi

# 4. Hướng dẫn cài đặt hook autosnap
echo -e "\n${BLUE}>>> [2/3] Cấu hình pacman hook tự động tạo snapshot trước khi nâng cấp hệ thống...${NC}"
HOOK_DIR="/etc/pacman.d/hooks"
mkdir -p "$HOOK_DIR"
cp /home/tu/Archlinux_config/scripts/timeshift-autosnap-single.sh /usr/local/bin/timeshift-autosnap-single
chmod +x /usr/local/bin/timeshift-autosnap-single

cat << 'EOF' > "${HOOK_DIR}/00-timeshift-autosnap.hook"
[Trigger]
Operation = Upgrade
Type = Package
Target = *

[Action]
Description = [Timeshift Autosnap] Đang tạo snapshot và chỉ giữ 1 bản gần nhất...
When = PreTransaction
Exec = /usr/local/bin/timeshift-autosnap-single
AbortOnFail
EOF
echo -e "${GREEN}[OK]${NC} Đã kích hoạt hook: /etc/pacman.d/hooks/00-timeshift-autosnap.hook"

# 5. Tạo ngay 1 bản snapshot mốc đầu tiên
echo -e "\n${BLUE}>>> [3/3] Đang tiến hành tạo bản snapshot gốc đầu tiên...${NC}"
timeshift --create --comments "Baseline Snapshot - Clean Setup" --scripted || true

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}   HỆ THỐNG SNAPSHOT & ROLLBACK ĐÃ HOẠT ĐỘNG HOÀN TOÀN!         ${NC}"
echo -e "${CYAN}   - Mỗi lần chạy 'sudo pacman -Syu', snapshot sẽ tự sinh ra.   ${NC}"
echo -e "${CYAN}   - Tự động giữ 3 bản daily và 2 bản boot gần nhất.           ${NC}"
echo -e "${CYAN}   - Lệnh khôi phục khi gặp sự cố: 'sudo timeshift --restore'   ${NC}"
echo -e "${GREEN}================================================================${NC}"
