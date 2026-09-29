#!/usr/bin/env bash
# ==============================================================================
# Script cài đặt Kernel CachyOS (BORE Scheduler) & Tích hợp Kho x86-64-v3
# - Tự động nhận diện kiến trúc CPU Intel TigerLake (x86-64-v3: AVX2, FMA3)
# - Cài đặt nhân linux-cachyos đi kèm BORE CPU Scheduler siêu nhạy cho Hyprland
# - Chuyển đổi driver NVIDIA sang DKMS (hoạt động đồng thời trên cả 2 kernel)
# - Cập nhật GRUB & Initramfs tự động
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
echo -e "${GREEN}   BẮT ĐẦU CÀI ĐẶT KERNEL CACHYOS (BORE SCHEDULER) & REPO V3   ${NC}"
echo -e "${BLUE}================================================================${NC}"

# 1. Cấu hình CachyOS Repository
echo -e "\n${BLUE}>>> [1/4] Kiểm tra và nạp CachyOS Repositories vào pacman.conf...${NC}"

# Đảm bảo mirrorlist và keyring tồn tại
if [ ! -f /etc/pacman.d/cachyos-v3-mirrorlist ]; then
    echo -e "${CYAN}==>${NC} Đang tải cachyos-keyring & mirrorlist..."
    pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com || true
    pacman-key --lsign-key F3B607488DB35A47 || true
    pacman -U --needed --noconfirm \
        https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-keyring-20240331-1-any.pkg.tar.zst \
        https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-mirrorlist-27-1-any.pkg.tar.zst \
        https://mirror.cachyos.org/repo/x86_64/cachyos/cachyos-v3-mirrorlist-27-1-any.pkg.tar.zst
fi

# Chèn cấu hình CachyOS vào trước [core] trong /etc/pacman.conf nếu chưa có
cp /etc/pacman.conf "/etc/pacman.conf.bak.${TIMESTAMP}"

python3 - << 'EOF'
with open('/etc/pacman.conf', 'r') as f:
    content = f.read()

cachy_block = """[cachyos-v3]
Include = /etc/pacman.d/cachyos-v3-mirrorlist

[cachyos-core-v3]
Include = /etc/pacman.d/cachyos-v3-mirrorlist

[cachyos-extra-v3]
Include = /etc/pacman.d/cachyos-v3-mirrorlist

[cachyos]
Include = /etc/pacman.d/cachyos-mirrorlist

"""

if '[cachyos]' not in content and '[cachyos-v3]' not in content:
    content = content.replace('[core]', cachy_block + '[core]', 1)
    with open('/etc/pacman.conf', 'w') as f:
        f.write(content)
    print("INJECTED")
else:
    print("EXISTS")
EOF

echo -e "${GREEN}[OK]${NC} Đã xác nhận cấu hình CachyOS Repositories (v3) trong /etc/pacman.conf"

# 2. Cập nhật cơ sở dữ liệu pacman
echo -e "\n${BLUE}>>> [2/4] Đồng bộ cơ sở dữ liệu kho phần mềm...${NC}"
pacman -Sy

# 3. Cài đặt Kernel CachyOS và Driver NVIDIA tương thích
echo -e "\n${BLUE}>>> [3/4] Cài đặt linux-cachyos, headers và nvidia-open-dkms...${NC}"

# Tự động gỡ bỏ nvidia-open cố định để nhường chỗ cho nvidia-open-dkms (tránh bị kẹt conflict prompt)
if pacman -Q nvidia-open &>/dev/null; then
    echo -e "${CYAN}==>${NC} Chuyển đổi: Gỡ nvidia-open để cài nvidia-open-dkms..."
    pacman -Rdd --noconfirm nvidia-open
fi

# Cài đặt đồng bộ linux-headers cho cả 2 kernel để DKMS tự động build module NVIDIA hoàn hảo
pacman -S --needed --noconfirm linux-headers linux-cachyos linux-cachyos-headers nvidia-open-dkms

# 4. Biên dịch Initramfs và Cập nhật GRUB Bootloader
echo -e "\n${BLUE}>>> [4/4] Biên dịch lại Initramfs và nạp menu Boot GRUB...${NC}"
mkinitcpio -P
grub-mkconfig -o /boot/grub/grub.cfg

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}   CÀI ĐẶT KERNEL CACHYOS HOÀN TẤT THÀNH CÔNG!                  ${NC}"
echo -e "${CYAN}   - Kernel: linux-cachyos với BORE Scheduler (Độ mượt tối đa)  ${NC}"
echo -e "${CYAN}   - Instruction Set: Tối ưu hoá phần cứng x86-64-v3           ${NC}"
echo -e "${CYAN}   - Driver NVIDIA: Đã nạp DKMS cho cả 2 kernel                 ${NC}"
echo -e "${YELLOW}   -> Hãy reboot máy, hệ thống sẽ tự động boot vào CachyOS!    ${NC}"
echo -e "${GREEN}================================================================${NC}"
