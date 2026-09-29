#!/usr/bin/env bash
# ==============================================================================
# Script tối ưu độ mượt hiển thị & Khắc phục đóng băng giao diện Caelestia / Hyprland
# - Khắc phục lỗi kẹt Panel Self Refresh (PSR) trên Intel TigerLake iGPU (màn hình đơ như ngủ đông)
# - Nâng xung tối thiểu iGPU lên 800MHz khi cắm sạc (AC) để chuyển cảnh 144Hz tức thì
# - Tự động hạ xung iGPU về 350MHz khi dùng pin để tiết kiệm năng lượng
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}==>${NC} Đang áp dụng các tối ưu độ mượt và chống đóng băng màn hình..."

# 1. Khắc phục triệt để lỗi màn hình 'ngủ đông / đóng băng' sau khi nhàn rỗi lâu
echo -e "${BLUE}>>> [1/3] Cấu hình driver Intel i915 (Tắt PSR - Panel Self Refresh)...${NC}"
cat << 'EOF' > /etc/modprobe.d/i915.conf
# Tắt PSR2/PSR trên Intel TigerLake để chống hiện tượng kẹt frame/treo màn hình khi idle
options i915 enable_psr=0
EOF
echo -e "${GREEN}[OK]${NC} Đã tạo /etc/modprobe.d/i915.conf (options i915 enable_psr=0)"

# 2. Cập nhật auto-power-profile hỗ trợ xung nhịp GPU động (Chỉ tăng hiệu năng khi cắm sạc)
if [ -f "$REPO_ROOT/system/auto-power-profile" ]; then
    cp "$REPO_ROOT/system/auto-power-profile" /usr/local/bin/auto-power-profile
elif [ -f "$REPO_ROOT/auto-power-profile" ]; then
    cp "$REPO_ROOT/auto-power-profile" /usr/local/bin/auto-power-profile
fi
chmod +x /usr/local/bin/auto-power-profile
echo -e "${GREEN}[OK]${NC} Đã đồng bộ /usr/local/bin/auto-power-profile"

# 3. Kích hoạt thiết lập ngay lập tức cho trạng thái nguồn hiện tại
echo -e "${BLUE}>>> [3/3] Áp dụng cấu hình nguồn hiện tại...${NC}"
/usr/local/bin/auto-power-profile
echo -e "${GREEN}[OK]${NC} Đã áp dụng hồ sơ điện áp & xung nhịp hiện tại."

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}   TỐI ƯU HIỂN THỊ & CHỐNG TREO MÀN HÌNH HOÀN TẤT!              ${NC}"
echo -e "${CYAN}   - Khi cắm sạc (AC): GPU Intel duy trì xung tối thiểu 800MHz  ${NC}"
echo -e "${CYAN}     cho hoạt ảnh Caelestia 144Hz siêu mượt và không khựng.     ${NC}"
echo -e "${CYAN}   - Khi dùng pin: Tự hạ về 350MHz giúp tiết kiệm pin tối đa.   ${NC}"
echo -e "${CYAN}   - Đã triệt tiêu lỗi treo giao diện 'ngủ đông' khi idle.      ${NC}"
echo -e "${GREEN}================================================================${NC}"
