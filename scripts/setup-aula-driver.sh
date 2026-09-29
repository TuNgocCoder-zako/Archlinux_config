#!/usr/bin/env bash
# ==============================================================================
# Setup WebHID Udev Rules for AULA Keyboards on Arch Linux
# Supports both wired modes (Vendor 2e3c, 3554) and 2.4G Compx Receiver (Vendor 3554)
# ==============================================================================

set -euo pipefail

UDEV_RULE_PATH="/etc/udev/rules.d/70-aula-webhid.rules"
WEBDRIVER_URL="https://www.aulastar.com/web-drive/"

log() { printf '==> %s\n' "$1"; }
err() { printf 'ERROR: %s\n' "$1" >&2; }

if [ "$(id -u)" -ne 0 ]; then
    err "Script này cần quyền root để tạo file udev rule."
    err "Vui lòng chạy lại bằng lệnh: sudo bash $0"
    exit 1
fi

log "Đang cấu hình udev rules cho thiết bị AULA & Compx Receiver..."

cat > "$UDEV_RULE_PATH" <<'EOF'
# AULA Keyboards & Compx Wireless Receiver WebHID access
# Cấp quyền cho user hiện tại truy cập qua WebHID trên trình duyệt nhân Chromium

# Aula Vendor ID 0x2e3c (WIN60 HE, etc.)
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="2e3c", MODE="0660", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="2e3c", MODE="0660", TAG+="uaccess"

# Compx / Aula 2.4G Receiver Vendor ID 0x3554 (F75, F87, F99, etc.)
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3554", MODE="0660", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="3554", MODE="0660", TAG+="uaccess"
EOF

log "Đã tạo rule tại $UDEV_RULE_PATH"

log "Nạp lại udev rules..."
udevadm control --reload-rules
udevadm trigger

echo
log "=========================================================="
log "Cấu hình thành công!"
log "1. Hãy rút receiver/cáp phím ra và cắm lại một lần để áp dụng quyền mới."
log "2. Mở trình duyệt Brave và truy cập: $WEBDRIVER_URL"
log "=========================================================="
