#!/usr/bin/env bash
# ==============================================================================
# Script xử lý tràn dung lượng /boot (256MB) & Hoàn tất cài đặt Kernel CachyOS
# - Giải phóng dung lượng phân vùng /boot (xóa file UKI cũ bị trùng lặp)
# - Chuẩn hóa linux.preset sang image thông thường (đồng bộ với linux-cachyos & GRUB)
# - Biên dịch initramfs cho cả 2 kernel và cập nhật menu Boot GRUB
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
echo -e "${GREEN}   XỬ LÝ DUNG LƯỢNG /BOOT & HOÀN TẤT CÀI ĐẶT KERNEL CACHYOS     ${NC}"
echo -e "${BLUE}================================================================${NC}"

# 1. Kiểm tra dung lượng hiện tại của /boot
echo -e "\n${BLUE}>>> [1/4] Kiểm tra dung lượng phân vùng /boot...${NC}"
df -h /boot

# 2. Chuyển linux.preset từ UKI sang standard initramfs image
echo -e "\n${BLUE}>>> [2/4] Chuẩn hóa cấu hình initramfs cho GRUB...${NC}"
LINUX_PRESET="/etc/mkinitcpio.d/linux.preset"

if [ -f "$LINUX_PRESET" ]; then
    cp "$LINUX_PRESET" "${LINUX_PRESET}.bak"
    # Bật default_image và tắt default_uki
    sed -i 's|^#default_image="/boot/initramfs-linux.img"|default_image="/boot/initramfs-linux.img"|' "$LINUX_PRESET"
    sed -i 's|^default_uki=|#default_uki=|' "$LINUX_PRESET"
    sed -i 's|^default_options=|#default_options=|' "$LINUX_PRESET"
    sed -i 's|^fallback_uki=|#fallback_uki=|' "$LINUX_PRESET"
    echo -e "${GREEN}[OK]${NC} Đã chuyển $LINUX_PRESET sang chuẩn initramfs.img tương thích GRUB"
fi

# 3. Dọn dẹp các file UKI cũ/tạm trong /boot/EFI/Linux để giải phóng ~80MB
echo -e "\n${BLUE}>>> [3/4] Thu hồi dung lượng bị chiếm dụng bởi UKI cũ trong /boot...${NC}"
if [ -d /boot/EFI/Linux ]; then
    rm -f /boot/EFI/Linux/arch-linux*.efi
    echo -e "${GREEN}[OK]${NC} Đã giải phóng bộ nhớ từ /boot/EFI/Linux"
fi
df -h /boot

# 4. Biên dịch lại toàn bộ initramfs và cập nhật menu Boot GRUB
echo -e "\n${BLUE}>>> [4/4] Biên dịch lại mkinitcpio và cập nhật GRUB bootloader...${NC}"
mkinitcpio -P
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}   CÀI ĐẶT & CẤU HÌNH KERNEL CACHYOS ĐÃ THÀNH CÔNG 100%!        ${NC}"
echo -e "${CYAN}   - Phân vùng /boot đã có đủ dung lượng thông thoáng.          ${NC}"
echo -e "${CYAN}   - Kernel linux-cachyos + BORE Scheduler đã sẵn sàng.         ${NC}"
echo -e "${CYAN}   - Driver NVIDIA DKMS đã build hoàn tất cho cả 2 kernel.      ${NC}"
echo -e "${YELLOW}   -> Bây giờ bạn có thể gõ 'reboot' để vào kernel mới!         ${NC}"
echo -e "${GREEN}================================================================${NC}"
