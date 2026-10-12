#!/usr/bin/env bash
# ==============================================================================
# CẤU HÌNH TIMESHIFT: GIỚI HẠN DUY NHẤT 1 BẢN SNAPSHOT TRÊN TOÀN HỆ THỐNG
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[LỖI]${NC} Vui lòng chạy script với quyền root: sudo $0"
    exit 1
fi

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}   THIẾT LẬP GIỚI HẠN TIMESHIFT CHỈ LƯU DUY NHẤT 1 BẢN GẦN NHẤT   ${NC}"
echo -e "${BLUE}================================================================${NC}"

# 1. Cài đặt script tự động cắt gọt snapshot vào /usr/local/bin
echo -e "\n${BLUE}>>> [1/4] Cài đặt /usr/local/bin/timeshift-autosnap-single...${NC}"
cp /home/tu/Archlinux_config/scripts/timeshift-autosnap-single.sh /usr/local/bin/timeshift-autosnap-single
chmod +x /usr/local/bin/timeshift-autosnap-single
echo -e "${GREEN}[OK]${NC} Đã cài đặt script quản lý snapshot."

# 2. Cập nhật hook pacman
echo -e "\n${BLUE}>>> [2/4] Cập nhật pacman hook /etc/pacman.d/hooks/00-timeshift-autosnap.hook...${NC}"
mkdir -p /etc/pacman.d/hooks
cat << 'EOF' > /etc/pacman.d/hooks/00-timeshift-autosnap.hook
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
echo -e "${GREEN}[OK]${NC} Đã cập nhật pacman hook."

# 3. Cập nhật /etc/timeshift/timeshift.json để giới hạn retention counts = 1
echo -e "\n${BLUE}>>> [3/4] Cập nhật cấu hình /etc/timeshift/timeshift.json...${NC}"
if [ -f /etc/timeshift/timeshift.json ]; then
    sed -i 's/"count_monthly" : "[0-9]*"/"count_monthly" : "0"/' /etc/timeshift/timeshift.json
    sed -i 's/"count_weekly" : "[0-9]*"/"count_weekly" : "0"/' /etc/timeshift/timeshift.json
    sed -i 's/"count_daily" : "[0-9]*"/"count_daily" : "1"/' /etc/timeshift/timeshift.json
    sed -i 's/"count_hourly" : "[0-9]*"/"count_hourly" : "0"/' /etc/timeshift/timeshift.json
    sed -i 's/"count_boot" : "[0-9]*"/"count_boot" : "1"/' /etc/timeshift/timeshift.json
    echo -e "${GREEN}[OK]${NC} Đã đặt count_daily=1, count_boot=1 trong cấu hình."
fi

# 4. Quét và xóa ngay lập tức các bản snapshot cũ, chỉ giữ 1 bản mới nhất
echo -e "\n${BLUE}>>> [4/4] Dọn dẹp các bản snapshot cũ đang chiếm dung lượng...${NC}"
SNAPSHOTS_DIR="/timeshift/snapshots"
if [ -d "$SNAPSHOTS_DIR" ]; then
    LATEST_SNAPSHOT=$(ls -1d "$SNAPSHOTS_DIR"/20* 2>/dev/null | sort | tail -n 1)
    if [ -n "$LATEST_SNAPSHOT" ]; then
        echo -e "${GREEN}  ✔ Bản snapshot mới nhất được giữ lại:${NC} $(basename "$LATEST_SNAPSHOT")"
        for snap in "$SNAPSHOTS_DIR"/20*; do
            if [ -d "$snap" ] && [ "$snap" != "$LATEST_SNAPSHOT" ]; then
                echo -e "${YELLOW}  - Đang xóa bản cũ:${NC} $(basename "$snap")..."
                rm -rf "$snap"
            fi
        done
        for link_dir in /timeshift/snapshots-*; do
            if [ -d "$link_dir" ]; then
                find "$link_dir" -xtype l -delete 2>/dev/null || true
            fi
        done
        echo -e "${GREEN}[OK] Đã dọn sạch các bản cũ thành công!${NC}"
    fi
fi

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}   HOÀN TẤT! TỪ NAY HỆ THỐNG SẼ CHỈ GIỮ DUY NHẤT 1 BẢN SNAPSHOT. ${NC}"
echo -e "${BLUE}================================================================${NC}"
df -h /
