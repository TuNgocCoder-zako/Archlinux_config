#!/usr/bin/env bash
# ==============================================================================
# TIMESHIFT AUTOSNAP SINGLE: TỰ ĐỘNG TẠO VÀ CHỈ GIỮ ĐÚNG 1 BẢN SNAPSHOT MỚI NHẤT
# ==============================================================================
# - Tạo snapshot an toàn trước khi pacman nâng cấp hệ thống.
# - Luôn tự động xóa các bản cũ, đảm bảo ổ cứng chỉ lưu duy nhất 1 bản mới nhất.
# ==============================================================================

set -e

SNAPSHOTS_DIR="/timeshift/snapshots"

# 1. Tạo bản snapshot mới
echo "[Timeshift Autosnap] Đang tạo bản snapshot hệ thống mới..."
/usr/bin/timeshift --create --comments "Pre-pacman-update auto snapshot" --scripted || true

# 2. Quét và chỉ giữ lại đúng 1 bản mới nhất
if [ -d "$SNAPSHOTS_DIR" ]; then
    LATEST_SNAPSHOT=$(ls -1d "$SNAPSHOTS_DIR"/20* 2>/dev/null | sort | tail -n 1)

    if [ -n "$LATEST_SNAPSHOT" ]; then
        for snap in "$SNAPSHOTS_DIR"/20*; do
            if [ -d "$snap" ] && [ "$snap" != "$LATEST_SNAPSHOT" ]; then
                echo "[Timeshift Autosnap] Xóa snapshot cũ: $(basename "$snap") (chỉ giữ 1 bản duy nhất)"
                rm -rf "$snap"
            fi
        done

        # Dọn dẹp các symlink hỏng nếu có
        for link_dir in /timeshift/snapshots-*; do
            if [ -d "$link_dir" ]; then
                find "$link_dir" -xtype l -delete 2>/dev/null || true
            fi
        done
        echo "[Timeshift Autosnap] Hoàn tất: Đang lưu duy nhất bản $(basename "$LATEST_SNAPSHOT")."
    fi
fi
