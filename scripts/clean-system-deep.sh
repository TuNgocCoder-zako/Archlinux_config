#!/usr/bin/env bash
# ==============================================================================
# DEEP SYSTEM CLEANUP: DỌN DẸP TIMESHIFT CŨ & GIẢI PHÓNG RAM BUFFER CACHE
# ==============================================================================
# - Xóa các bản snapshot Timeshift cũ dư thừa, giữ lại bản snapshot hoàn chỉnh nhất.
# - Đồng bộ dữ liệu và giải phóng toàn bộ bộ nhớ đệm RAM (Buffer/Cache).
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[LỖI]${NC} Vui lòng chạy với quyền root: sudo $0"
    exit 1
fi

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}      BẮT ĐẦU DỌN DẸP CHUYÊN SÂU HỆ THỐNG (NHÓM 3 & NHÓM 5)      ${NC}"
echo -e "${BLUE}================================================================${NC}"

# 1. Dọn dẹp Nhóm 3: Timeshift Snapshots cũ
echo -e "\n${CYAN}>>> [1/2] Đang dọn dẹp các bản snapshot Timeshift cũ...${NC}"
SNAPSHOTS_DIR="/timeshift/snapshots"

if [ -d "$SNAPSHOTS_DIR" ]; then
    # Tìm bản snapshot mới nhất
    LATEST_SNAPSHOT=$(ls -1d "$SNAPSHOTS_DIR"/* 2>/dev/null | sort | tail -n 1)

    if [ -n "$LATEST_SNAPSHOT" ]; then
        echo -e "${BLUE}  ℹ Bản snapshot mới nhất sẽ được GIỮ LẠI:${NC} $(basename "$LATEST_SNAPSHOT")"

        # Xóa các bản snapshot cũ hơn
        for snap in "$SNAPSHOTS_DIR"/*; do
            if [ "$snap" != "$LATEST_SNAPSHOT" ] && [ -d "$snap" ]; then
                echo -e "${YELLOW}  - Đang xóa snapshot cũ:${NC} $(basename "$snap")..."
                rm -rf "$snap"
            fi
        done

        # Dọn dẹp symlink hỏng trong các thư mục liên kết
        for link_dir in /timeshift/snapshots-*; do
            if [ -d "$link_dir" ]; then
                find "$link_dir" -xtype l -delete 2>/dev/null || true
            fi
        done

        echo -e "${GREEN}[OK] Đã dọn sạch các bản snapshot cũ!${NC}"
    fi
else
    echo -e "${YELLOW}[!] Không tìm thấy thư mục /timeshift/snapshots.${NC}"
fi

# 2. Dọn dẹp Nhóm 5: Giải phóng RAM Buffer Cache
echo -e "\n${CYAN}>>> [2/2] Đang giải phóng bộ nhớ RAM (drop_caches)...${NC}"
sync
echo 3 > /proc/sys/vm/drop_caches
echo -e "${GREEN}[OK] Đã giải phóng toàn bộ Buffer/Cache RAM!${NC}"

# Hiển thị kết quả
echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}           KẾT QUẢ DỌN DẸP HỆ THỐNG THỰC TẾ                      ${NC}"
echo -e "${BLUE}================================================================${NC}"
df -h /
echo "----------------------------------------------------------------"
free -h
echo -e "${GREEN}================================================================${NC}"
