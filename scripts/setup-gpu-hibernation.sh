#!/usr/bin/env bash
# ==============================================================================
# Script tối ưu nguồn điện cho card rời NVIDIA (RTX 3050 Mobile / Hybrid Graphics)
# - Cho phép GPU NVIDIA đi vào trạng thái ngủ đông sâu (Runtime D3cold 0W) khi không dùng.
# - Tự động thức dậy ngay lập tức khi chạy AI (Ollama, Whisper, PyTorch, Prime-run).
# ==============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[LỖI]${NC} Vui lòng chạy script này với quyền root: sudo $0"
    exit 1
fi

echo -e "${BLUE}==>${NC} Đang cấu hình chế độ ngủ đông sâu (D3cold) cho GPU NVIDIA..."

# 1. Chặn Xorg (SDDM greeter) tự động chiếm dụng bộ nhớ VRAM của GPU NVIDIA
mkdir -p /etc/X11/xorg.conf.d
cat << 'EOF' > /etc/X11/xorg.conf.d/10-intel.conf
# Chỉ định Xorg chỉ chạy trên Intel iGPU, không tự động kích hoạt card rời NVIDIA
Section "ServerFlags"
    Option "AutoAddGPU" "off"
EndSection

Section "Device"
    Identifier "Intel Graphics"
    Driver "modesetting"
    BusID "PCI:0:2:0"
EndSection
EOF
echo -e "${GREEN}[OK]${NC} Đã tạo /etc/X11/xorg.conf.d/10-intel.conf (Ngăn Xorg giữ 4MB VRAM trên NVIDIA)"

# 2. Đảm bảo chế độ Dynamic Power Management (0x02) được kích hoạt
cat << 'EOF' > /etc/modprobe.d/nvidia-pm.conf
options nvidia NVreg_DynamicPowerManagement=0x02
EOF
echo -e "${GREEN}[OK]${NC} Đã xác nhận /etc/modprobe.d/nvidia-pm.conf (NVreg_DynamicPowerManagement=0x02)"

# 3. Đảm bảo udev rules tự động chuyển GPU về auto power management
cat << 'EOF' > /etc/udev/rules.d/80-nvidia-pm.rules
# Enable runtime PM for NVIDIA VGA/3D controller devices on Driver binds
ACTION=="add|bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="auto"
ACTION=="add|bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="auto"

# Disable runtime PM for NVIDIA VGA/3D controller devices on Driver unbinds
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", TEST=="power/control", ATTR{power/control}="on"
ACTION=="unbind", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", TEST=="power/control", ATTR{power/control}="on"

# Enable runtime PM for NVIDIA Audio devices
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", TEST=="power/control", ATTR{power/control}="auto"
EOF
echo -e "${GREEN}[OK]${NC} Đã cấu hình /etc/udev/rules.d/80-nvidia-pm.rules"

echo -e "\n${GREEN}==> HOÀN TẤT THIẾT LẬP!${NC}"
echo -e "${YELLOW}Ghi chú:${NC} Sau khi khởi động lại máy (hoặc restart SDDM):"
echo " - Khi rảnh rỗi (idle): 'cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status' sẽ báo 'suspended' (GPU ăn 0W, quạt tắt, hoàn toàn mát mẻ)."
echo " - Khi chạy AI (Ollama / Whisper): GPU tự động thức dậy, thực thi tính toán tốc độ cao rồi tự ngủ lại sau khi hoàn thành."
