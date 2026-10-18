#!/usr/bin/env bash
# ==============================================================================
# INSTALL SYSTEM RULES & DAEMONS (Udev, Limits, Ananicy, Auto-Power-Profile)
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[LỖI]${NC} Vui lòng chạy với quyền root: sudo $0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_DIR="$SCRIPT_DIR"

echo -e "${BLUE}>>> Cài đặt các quy tắc phần cứng và giới hạn hiệu năng hệ thống...${NC}"

# 1. Power management udev rule
if [ -f "$SYSTEM_DIR/95-power-management.rules" ]; then
    cp "$SYSTEM_DIR/95-power-management.rules" /etc/udev/rules.d/
    udevadm control --reload-rules
    udevadm trigger --subsystem-match=power_supply || true
    udevadm trigger --subsystem-match=pci || true
    echo -e "${GREEN}[OK]${NC} Đã cài đặt /etc/udev/rules.d/95-power-management.rules"
fi

# 2. File descriptor limits
if [ -f "$SYSTEM_DIR/99-dev-nofile.conf" ]; then
    mkdir -p /etc/security/limits.d/
    cp "$SYSTEM_DIR/99-dev-nofile.conf" /etc/security/limits.d/
    echo -e "${GREEN}[OK]${NC} Đã cài đặt /etc/security/limits.d/99-dev-nofile.conf"
fi

# 3. Ananicy custom rules for Hyprland & Caelestia
if [ -f "$SYSTEM_DIR/99-hyprland-custom.rules" ]; then
    mkdir -p /etc/ananicy.d/
    cp "$SYSTEM_DIR/99-hyprland-custom.rules" /etc/ananicy.d/
    systemctl restart ananicy-cpp 2>/dev/null || true
    echo -e "${GREEN}[OK]${NC} Đã cài đặt /etc/ananicy.d/99-hyprland-custom.rules"
fi

# 4. Sysctl limits
if [ -f "$SYSTEM_DIR/99-limits.conf" ]; then
    mkdir -p /etc/sysctl.d/
    cp "$SYSTEM_DIR/99-limits.conf" /etc/sysctl.d/
    sysctl --system >/dev/null 2>&1 || true
    echo -e "${GREEN}[OK]${NC} Đã cài đặt /etc/sysctl.d/99-limits.conf"
fi

# 5. Auto power profile script and service
if [ -f "$SYSTEM_DIR/auto-power-profile" ]; then
    cp "$SYSTEM_DIR/auto-power-profile" /usr/local/bin/auto-power-profile
    chmod +x /usr/local/bin/auto-power-profile
    /usr/local/bin/auto-power-profile || true
    echo -e "${GREEN}[OK]${NC} Đã cài đặt và kích hoạt /usr/local/bin/auto-power-profile"
fi

if [ -f "$SYSTEM_DIR/auto-power-profile.service" ]; then
    cp "$SYSTEM_DIR/auto-power-profile.service" /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable --now auto-power-profile.service 2>/dev/null || true
    echo -e "${GREEN}[OK]${NC} Đã kích hoạt auto-power-profile.service"
fi

echo -e "\n${GREEN}[OK] Đã hoàn tất cài đặt toàn bộ System Rules!${NC}"
