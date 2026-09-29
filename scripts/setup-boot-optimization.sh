#!/usr/bin/env bash
# ==============================================================================
# Script tối ưu tốc độ khởi động (Boot Time Optimization) & Docker Socket
# - Chuyển Docker sang Socket Activation: Tiết kiệm ~1.1s boot time và ~100MB RAM ban đầu.
# - Rút ngắn GRUB Timeout từ 5s xuống 1s: Giảm thời gian chờ bootloader.
# - Cấu hình Early KMS cho Intel iGPU (i915): Chống nháy màn hình, chuyển mượt sang SDDM.
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

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}   BẮT ĐẦU TỐI ƯU THỜI GIAN KHỞI ĐỘNG (BOOT TIME OPTIMIZATION)   ${NC}"
echo -e "${BLUE}================================================================${NC}"

# ------------------------------------------------------------------------------
# 1. Tối ưu Docker Daemon: Chuyển sang Socket Activation
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}>>> [1/3] Cấu hình Docker Socket Activation...${NC}"
if systemctl is-enabled docker.service &>/dev/null; then
    systemctl disable docker.service
    echo -e "${GREEN}[OK]${NC} Đã tắt khởi động cùng hệ thống của docker.service"
else
    echo -e "${YELLOW}[INFO]${NC} docker.service vốn đã không bật lúc boot"
fi

systemctl enable docker.socket
systemctl restart docker.socket
echo -e "${GREEN}[OK]${NC} Đã kích hoạt docker.socket (Docker daemon sẽ chỉ thức dậy khi được gọi)"

# ------------------------------------------------------------------------------
# 2. Tinh chỉnh GRUB Timeout
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}>>> [2/3] Tinh chỉnh GRUB Bootloader Timeout...${NC}"
GRUB_DEFAULT_FILE="/etc/default/grub"

if [ -f "$GRUB_DEFAULT_FILE" ]; then
    cp "$GRUB_DEFAULT_FILE" "${GRUB_DEFAULT_FILE}.bak.${TIMESTAMP}"
    echo -e "${GREEN}[OK]${NC} Đã sao lưu $GRUB_DEFAULT_FILE -> ${GRUB_DEFAULT_FILE}.bak.${TIMESTAMP}"

    # Đặt GRUB_TIMEOUT=1
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' "$GRUB_DEFAULT_FILE"

    # Đảm bảo GRUB_RECORDFAIL_TIMEOUT cũng là 1 (tránh bị kẹt 30s nếu lần trước tắt nguồn đột ngột)
    if grep -q "^GRUB_RECORDFAIL_TIMEOUT=" "$GRUB_DEFAULT_FILE"; then
        sed -i 's/^GRUB_RECORDFAIL_TIMEOUT=.*/GRUB_RECORDFAIL_TIMEOUT=1/' "$GRUB_DEFAULT_FILE"
    else
        echo 'GRUB_RECORDFAIL_TIMEOUT=1' >> "$GRUB_DEFAULT_FILE"
    fi

    echo -e "${GREEN}[OK]${NC} Đã cập nhật GRUB_TIMEOUT=1 và GRUB_RECORDFAIL_TIMEOUT=1"
    echo -e "${CYAN}==>${NC} Đang cập nhật grub.cfg..."
    grub-mkconfig -o /boot/grub/grub.cfg
    echo -e "${GREEN}[OK]${NC} Đã build lại /boot/grub/grub.cfg"
else
    echo -e "${YELLOW}[CẢNH BÁO]${NC} Không tìm thấy $GRUB_DEFAULT_FILE, bỏ qua bước cấu hình GRUB."
fi

# ------------------------------------------------------------------------------
# 3. Thêm Early KMS cho Intel iGPU (i915) vào mkinitcpio
# ------------------------------------------------------------------------------
echo -e "\n${BLUE}>>> [3/3] Cấu hình Early KMS cho Intel iGPU trong initramfs...${NC}"
MKINITCPIO_CONF="/etc/mkinitcpio.conf"

if [ -f "$MKINITCPIO_CONF" ]; then
    cp "$MKINITCPIO_CONF" "${MKINITCPIO_CONF}.bak.${TIMESTAMP}"
    echo -e "${GREEN}[OK]${NC} Đã sao lưu $MKINITCPIO_CONF -> ${MKINITCPIO_CONF}.bak.${TIMESTAMP}"

    # Kiểm tra xem i915 đã có trong MODULES chưa
    if grep -E "^MODULES=.*i915" "$MKINITCPIO_CONF" &>/dev/null; then
        echo -e "${YELLOW}[INFO]${NC} Module i915 đã tồn tại trong MODULES."
    else
        # Thêm i915 vào đầu mảng MODULES=(...)
        sed -i -E 's/^MODULES=\((.*)\)/MODULES=(i915 \1)/' "$MKINITCPIO_CONF"
        echo -e "${GREEN}[OK]${NC} Đã thêm module i915 vào đầu MODULES trong $MKINITCPIO_CONF"
    fi

    echo -e "${CYAN}==>${NC} Đang biên dịch lại initramfs với mkinitcpio..."
    mkinitcpio -P
    echo -e "${GREEN}[OK]${NC} Đã build lại initramfs thành công!"
else
    echo -e "${YELLOW}[CẢNH BÁO]${NC} Không tìm thấy $MKINITCPIO_CONF, bỏ qua bước initramfs."
fi

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}   HOÀN TẤT TỐI ƯU KHỞI ĐỘNG HỆ THỐNG!                          ${NC}"
echo -e "${CYAN}   1. Docker: Chuyển sang socket-activated (giảm ~1s boot time) ${NC}"
echo -e "${CYAN}   2. GRUB: Timeout 1s (giảm 4s chờ bootloader)                 ${NC}"
echo -e "${CYAN}   3. Intel iGPU: Nạp early KMS (boot mượt, không flicker)       ${NC}"
echo -e "${YELLOW}   -> Hãy reboot máy và chạy 'systemd-analyze' để kiểm tra kết quả!${NC}"
echo -e "${GREEN}================================================================${NC}"
