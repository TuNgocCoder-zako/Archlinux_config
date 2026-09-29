#!/usr/bin/env bash
# ==============================================================================
# Script tối ưu Bluetooth Linux đạt trải nghiệm mượt mà như Windows
# Dành cho Arch Linux + Hyprland (Tối ưu đặc biệt cho chip MediaTek MT7921 / bàn phím BLE)
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

echo -e "${BLUE}==>${NC} Bắt đầu tối ưu hóa hệ thống Bluetooth theo chuẩn Windows..."

# 1. Tối ưu cấu hình BlueZ (/etc/bluetooth/main.conf)
mkdir -p /etc/bluetooth
if [ -f /etc/bluetooth/main.conf ] && [ ! -f /etc/bluetooth/main.conf.orig ]; then
    cp /etc/bluetooth/main.conf /etc/bluetooth/main.conf.orig
    echo -e "${GREEN}[OK]${NC} Đã sao lưu /etc/bluetooth/main.conf thành main.conf.orig"
fi

# Tinh chỉnh các tham số quan trọng trong main.conf
# FastConnectable: Giúp phím thức dậy kết nối tức thì (như Windows Fast Page Scan)
# AutoEnable: Luôn tự bật Bluetooth khi boot
# JustWorksRepairing: Tự động khôi phục kết nối mà không hỏi quyền phiền phức
# Experimental: Hỗ trợ báo pin và các tính năng BLE hiện đại
python3 - << 'EOF'
import re

conf_path = '/etc/bluetooth/main.conf'
try:
    with open(conf_path, 'r') as f:
        content = f.read()
except FileNotFoundError:
    content = "[General]\n[Policy]\n"

def set_opt(text, section, key, val):
    sec_pattern = rf"(\[{section}\][^\[]*)"
    sec_match = re.search(sec_pattern, text, re.IGNORECASE)
    if not sec_match:
        text += f"\n[{section}]\n{key} = {val}\n"
        return text
    
    sec_text = sec_match.group(1)
    key_pattern = rf"^[#\s]*({key}\s*=.*)$"
    new_key_line = f"{key} = {val}"
    
    if re.search(key_pattern, sec_text, re.MULTILINE):
        sec_text = re.sub(key_pattern, new_key_line, sec_text, flags=re.MULTILINE)
    else:
        sec_text = sec_text.rstrip() + f"\n{new_key_line}\n"
        
    text = text[:sec_match.start(1)] + sec_text + text[sec_match.end(1):]
    return text

content = set_opt(content, 'General', 'FastConnectable', 'true')
content = set_opt(content, 'General', 'JustWorksRepairing', 'always')
content = set_opt(content, 'General', 'Experimental', 'true')
content = set_opt(content, 'Policy', 'AutoEnable', 'true')
content = set_opt(content, 'Policy', 'ReconnectAttempts', '7')
content = set_opt(content, 'Policy', 'ReconnectIntervals', '1, 2, 4, 8, 16, 32, 64')

with open(conf_path, 'w') as f:
    f.write(content)
EOF
echo -e "${GREEN}[OK]${NC} Đã cấu hình /etc/bluetooth/main.conf (FastConnectable, AutoEnable, JustWorksRepairing)"

# 2. Tối ưu HID Input Service (/etc/bluetooth/input.conf)
# UserspaceHID=persist: Giữ kết nối phím ở tầng hệ thống luôn mở giống Windows HID Miniport
if [ -f /etc/bluetooth/input.conf ] && [ ! -f /etc/bluetooth/input.conf.orig ]; then
    cp /etc/bluetooth/input.conf /etc/bluetooth/input.conf.orig
    echo -e "${GREEN}[OK]${NC} Đã sao lưu /etc/bluetooth/input.conf thành input.conf.orig"
fi

cat << 'EOF' > /etc/bluetooth/input.conf
# Cấu hình tối ưu Input Bluetooth chuẩn Windows
[General]
# Giữ virtual input device node luôn hoạt động để không bị mất chữ cái đầu khi thức dậy
UserspaceHID=persist
IdleTimeout=0
LEAutoSecurity=true
EOF
echo -e "${GREEN}[OK]${NC} Đã cấu hình /etc/bluetooth/input.conf (UserspaceHID=persist)"

# 3. Tắt chế độ USB Autosuspend cho driver Bluetooth (btusb)
# Tránh trường hợp Linux cho chip MediaTek MT7921 Bluetooth ngủ đông quá sớm
cat << 'EOF' > /etc/modprobe.d/bluetooth-mtk.conf
# Tắt USB autosuspend mặc định cho btusb để giữ kết nối ổn định như Windows
options btusb enable_autosuspend=0
EOF
echo -e "${GREEN}[OK]${NC} Đã tạo /etc/modprobe.d/bluetooth-mtk.conf (enable_autosuspend=0)"

# 4. Tạo rule udev ngăn USB Bluetooth đi vào chế độ tiết kiệm điện sâu
cat << 'EOF' > /etc/udev/rules.d/99-bluetooth-power.rules
# Giữ nguồn cho chip Bluetooth MediaTek MT7921 (13d3:3563 và các biến thể) luôn sẵn sàng
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="13d3", ATTR{idProduct}=="3563", ATTR{power/control}="on"
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", ATTR{power/control}="on"
EOF
echo -e "${GREEN}[OK]${NC} Đã tạo /etc/udev/rules.d/99-bluetooth-power.rules"

# 5. Tạo script quản lý nguồn Bluetooth theo sạc (/usr/local/bin/bluetooth-ac-power)
# Luôn bật nguồn Bluetooth trước khi đăng nhập nếu cắm sạc, tắt khi chạy pin
cat << 'EOF' > /usr/local/bin/bluetooth-ac-power
#!/usr/bin/env bash
# Quản lý nguồn Bluetooth tự động theo trạng thái cắm sạc AC
# Cắm sạc -> Luôn bật Bluetooth sẵn sàng (kể cả trước khi đăng nhập)
# Chạy pin -> Tắt Bluetooth để tiết kiệm pin

is_ac_online() {
    for p in /sys/class/power_supply/*; do
        if [ -f "$p/type" ] && [ -f "$p/online" ]; then
            stype=$(cat "$p/type" 2>/dev/null)
            if [ "$stype" = "Mains" ] || [ "$stype" = "USB" ]; then
                if [ "$(cat "$p/online" 2>/dev/null)" = "1" ]; then
                    return 0
                fi
            fi
        fi
    done
    return 1
}

if is_ac_online; then
    # Đang cắm sạc: Bật Bluetooth
    rfkill unblock bluetooth 2>/dev/null || true
    for i in {1..10}; do
        if bluetoothctl show 2>/dev/null | grep -q "Powered:"; then
            break
        fi
        sleep 0.2
    done
    bluetoothctl power on >/dev/null 2>&1 || true
else
    # Không cắm sạc (Pin): Tắt Bluetooth
    bluetoothctl power off >/dev/null 2>&1 || true
    rfkill block bluetooth 2>/dev/null || true
fi
EOF
chmod +x /usr/local/bin/bluetooth-ac-power
echo -e "${GREEN}[OK]${NC} Đã tạo /usr/local/bin/bluetooth-ac-power"

# 6. Tạo systemd service khởi động trước màn hình đăng nhập (SDDM)
cat << 'EOF' > /etc/systemd/system/bluetooth-ac-power.service
[Unit]
Description=Bluetooth AC Power Manager (Power ON on AC before login, OFF on Battery)
After=bluetooth.service systemd-rfkill.service
Before=display-manager.service sddm.service
Wants=bluetooth.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/bluetooth-ac-power
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
echo -e "${GREEN}[OK]${NC} Đã tạo /etc/systemd/system/bluetooth-ac-power.service"

# 7. Tạo udev rule tự động đồng bộ khi cắm/rút sạc trong lúc đang dùng máy
cat << 'EOF' > /etc/udev/rules.d/98-bluetooth-ac.rules
# Tự động bật Bluetooth khi cắm sạc và tắt khi rút sạc
SUBSYSTEM=="power_supply", ACTION=="change", RUN+="/usr/local/bin/bluetooth-ac-power"
EOF
echo -e "${GREEN}[OK]${NC} Đã tạo /etc/udev/rules.d/98-bluetooth-ac.rules"

# 8. Kích hoạt dịch vụ, nạp lại systemd & udev
systemctl daemon-reload
systemctl enable --now bluetooth-ac-power.service
udevadm control --reload-rules && udevadm trigger
systemctl restart bluetooth
echo -e "${GREEN}[OK]${NC} Đã khởi động lại dịch vụ bluetooth.service và bật bluetooth-ac-power.service thành công!"

echo -e "\n${YELLOW}==> HOÀN TẤT TỐI ƯU HÓA BLUETOOTH THEO NGUỒN SẠC!${NC}"
echo -e "✦ Khi CẮM SẠC: Bluetooth luôn mở sẵn sàng ngay từ trước màn hình đăng nhập để kết nối bàn phím."
echo -e "✦ Khi CHẠY PIN: Bluetooth sẽ tự động tắt để tiết kiệm pin tối đa."

