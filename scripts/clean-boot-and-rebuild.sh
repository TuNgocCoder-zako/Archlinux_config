#!/usr/bin/env bash
# ==============================================================================
# Script giải phóng triệt để phân vùng /boot (256MB) & Tối ưu Initramfs cho Laptop
# - Loại bỏ NVIDIA khỏi Early KMS: Laptop hybrid chạy Hyprland trên Intel iGPU (i915).
#   Việc nhét NVIDIA vào initramfs lãng phí 60MB firmware GSP không cần thiết.
# - Hạ kích thước initramfs từ ~85MB xuống chỉ còn ~20MB/kernel!
# - Cả 2 kernel (CachyOS + Arch) chỉ tốn ~40MB, /boot 256MB sẽ còn dư hơn 120MB trống!
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
echo -e "${GREEN}   BẮT ĐẦU TỐI ƯU HÓA PHÂN VÙNG /BOOT & HOÀN TẤT CACHYOS       ${NC}"
echo -e "${BLUE}================================================================${NC}"

# 1. Ghi lại báo cáo dung lượng để kiểm tra
echo -e "\n${BLUE}>>> [1/5] Thống kê file trong /boot trước khi dọn dẹp...${NC}"
find /boot -type f -exec ls -lh {} + 2>/dev/null | awk '{print $5, $9}' | sort -hr | head -n 15 || true

# 2. Xóa các file thừa và file initramfs cũ/lỗi để giải phóng tức thì dung lượng
echo -e "\n${BLUE}>>> [2/5] Dọn dẹp các file tạm, UKI và initramfs cũ bị phình to...${NC}"
rm -f /boot/*.tmp* /boot/.*.tmp* /boot/*fallback* 2>/dev/null || true
rm -rf /boot/EFI/Linux 2>/dev/null || true
rm -f /boot/initramfs-linux*.img 2>/dev/null || true

echo -e "${GREEN}[OK]${NC} Dung lượng phân vùng /boot sau khi thu hồi:"
df -h /boot

# 3. Tinh chỉnh mkinitcpio.conf: Chỉ giữ i915 trong MODULES (chuẩn Laptop Optimus)
echo -e "\n${BLUE}>>> [3/5] Tối ưu hóa cấu hình initramfs (Giảm 60MB dung lượng thừa của NVIDIA GSP)...${NC}"
MKINITCPIO_CONF="/etc/mkinitcpio.conf"

# Chỉ nạp i915 trong initramfs, NVIDIA sẽ do udev nạp tự động khi dùng prime-run/CUDA
sed -i 's/^MODULES=.*/MODULES=(i915)/' "$MKINITCPIO_CONF"

# Cấu hình nén zstd tiêu chuẩn và ổn định
sed -i 's/^COMPRESSION=.*/COMPRESSION="zstd"/' "$MKINITCPIO_CONF"
sed -i 's/^COMPRESSION_OPTIONS=.*/COMPRESSION_OPTIONS=(-T0)/' "$MKINITCPIO_CONF"
if ! grep -q "^COMPRESSION_OPTIONS=" "$MKINITCPIO_CONF"; then
    echo 'COMPRESSION_OPTIONS=(-T0)' >> "$MKINITCPIO_CONF"
fi

# 4. Chuẩn hóa preset cho cả 2 kernel
cat << 'EOF' > /etc/mkinitcpio.d/linux-cachyos.preset
ALL_kver="/boot/vmlinuz-linux-cachyos"
PRESETS=('default')
default_image="/boot/initramfs-linux-cachyos.img"
EOF

cat << 'EOF' > /etc/mkinitcpio.d/linux.preset
ALL_kver="/boot/vmlinuz-linux"
PRESETS=('default')
default_image="/boot/initramfs-linux.img"
EOF
echo -e "${GREEN}[OK]${NC} Đã tối ưu hóa preset và mkinitcpio.conf"

# 5. Biên dịch tuần tự cho từng kernel và cập nhật GRUB
echo -e "\n${BLUE}>>> [4/5] Đang biên dịch initramfs siêu gọn nhẹ cho linux-cachyos...${NC}"
mkinitcpio -p linux-cachyos

echo -e "\n${BLUE}>>> [5/5] Đang biên dịch initramfs cho linux (Arch gốc) & nạp menu GRUB...${NC}"
mkinitcpio -p linux
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}   CÀI ĐẶT THÀNH CÔNG RỰC RỠ! DUNG LƯỢNG /BOOT SAU CÙNG:        ${NC}"
df -h /boot
echo -e "${CYAN}   - Cả 2 kernel (CachyOS + Arch) đã được nạp an toàn vào GRUB. ${NC}"
echo -e "${CYAN}   - Khởi động Hyprland mượt mà trên Intel iGPU 144Hz.          ${NC}"
echo -e "${YELLOW}   -> Hãy gõ 'reboot' để tận hưởng ngay Kernel CachyOS BORE!    ${NC}"
echo -e "${GREEN}================================================================${NC}"
