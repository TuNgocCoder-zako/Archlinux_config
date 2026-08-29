# 🌸 Arch Linux + Hyprland + Caelestia Shell — Dotfiles

```
  ╔═══════════════════════════════════════════════╗
  ║                                               ║
  ║   🌸 Arch Linux Rice — Caelestia Shell 🌸     ║
  ║   Hyprland + Material You Dynamic Theming     ║
  ║   Anime Aesthetic • Bare Metal Ready           ║
  ║                                               ║
  ╚═══════════════════════════════════════════════╝
```

## ✨ Features

- **Caelestia Shell** — Modern Material You desktop shell (Quickshell/QML)
- **Dynamic Theming** — Wallpaper-based color extraction (Material You)
- **Hyprland WM** — Wayland tiling compositor with smooth animations
- **Anime Aesthetic** — Catppuccin Mocha fallback palette, anime wallpapers
- **All-in-One Control Center** — Quick toggles, media player, sliders
- **Side Dock** — Clock, calendar, workspace indicator, power menu
- **Foot Terminal** — Lightweight Wayland-native terminal
- **Fuzzel Launcher** — Fast, Material You-styled app launcher
- **Cava Visualizer** — Audio visualizer integrated with media player
- **Momoisay** — Anime ASCII art greeting in terminal (Blue Archive)
- **Thunar** — File manager with right-click "Set as Wallpaper" action

## 📁 Structure

```
.
├── install.sh                    # Automated installer
├── dotfiles/
│   ├── caelestia/
│   │   ├── hypr-vars.lua         # Caelestia variables & keybinds
│   │   └── hypr-user.conf        # Hyprland user overrides
│   ├── hypr/
│   │   ├── env.conf              # Environment variables
│   │   └── hypridle.conf         # Auto-lock & screen off
│   ├── foot/
│   │   └── foot.ini              # Terminal (Catppuccin Mocha)
│   ├── fuzzel/
│   │   └── fuzzel.ini            # App launcher
│   ├── mako/
│   │   └── config                # Notification daemon (fallback)
│   ├── gtk-3.0/
│   │   └── settings.ini          # GTK theme settings
│   ├── fastfetch/
│   │   └── config.jsonc          # System info display
│   ├── cava/
│   │   └── config                # Audio visualizer
│   ├── fish/
│   │   └── config.fish           # Fish shell config
│   └── Thunar/
│       └── uca.xml               # Set wallpaper custom action
├── scripts/
│   ├── set-wallpaper             # Wallpaper setter (Caelestia)
│   └── fix-vmware-net.sh         # VMware network fix (optional)
└── README.md
```

## 🚀 Quick Install

### Prerequisites
- Arch Linux installed via `archinstall` (Minimal profile, UEFI, PipeWire, NetworkManager)
- Internet connection
- Non-root user with sudo access

### Installation

```bash
# Clone the repository
git clone https://github.com/TuNgocCoder-zako/Archlinux_config.git
cd Archlinux_config

# Run the installer
chmod +x install.sh
./install.sh
```

The installer will:
1. Update system & install `yay` (AUR helper)
2. Install Hyprland, Foot, Thunar, PipeWire, and all dependencies
3. Install `caelestia-cli` and run `caelestia install`
4. Copy custom dotfiles (keybinds, terminal theme, wallpaper actions)
5. Install bonus tools (Cava, Momoisay, Fastfetch)
6. Download anime wallpapers
7. Enable system services

## ⌨️ Key Bindings (Đầy đủ phím tắt)

| Phím tắt | Chức năng | Ghi chú |
|----------|-----------|---------|
| `Super + Return` / `Super + T` | Mở Terminal (Foot) | Anime Momoisay Greeting |
| `Super + D` / `Alt + D` | Menu ứng dụng (Fuzzel / Caelestia Launcher) | Tìm kiếm app & gõ lệnh `>` |
| `Super + V` / `Alt + V` | Lịch sử Clipboard (Cliphist) | Chọn lại text/ảnh đã copy |
| `Super + C` / `Alt + C` | Sóng âm thanh (Cava Audio Visualizer) | 6 dải màu Anime Gradient |
| `Super + I` / `Alt + I` | Cửa sổ thông tin hệ thống (Fastfetch) | Cửa sổ nổi bo tròn |
| `Super + N` | Bật/Tắt Bảng điều khiển (Sidebar / Control Center) | Toggles, Sliders, Music |
| `Super + E` | Quản lý tệp tin (Thunar File Manager) | Chuột phải đổi hình nền |
| `Super + W` | Trình duyệt Web (Firefox) | |
| `Super + L` | Khóa màn hình (Caelestia Lock Screen) | Nhạc, thời tiết, avatar |
| `Super + Q` / `Alt + Q` | Đóng cửa sổ hiện tại | |
| `Super + F` | Phóng to toàn màn hình (Fullscreen) | |
| `Alt + Space` / `Super + V` | Chuyển đổi cửa sổ dạng nổi (Toggle Floating) | |
| `Alt + S` | Chụp ảnh màn hình (Lưu vào Clipboard) | Có thông báo |
| `Super + Shift + S` | Chụp ảnh màn hình + Mở công cụ vẽ ghi chú (Swappy) | Vẽ mũi tên, che mờ |
| `Super + 1-9` | Chuyển đổi Workspace 1 - 9 | |
| `Super + Shift + Q` | Đăng xuất / Thoát Hyprland | |

## 🎨 Wallpaper & Material You Dynamic Theming

Caelestia Shell tự động trích xuất bảng màu chủ đạo từ hình nền Anime của bạn và áp dụng đồng bộ toàn hệ thống:

```bash
# Đổi hình nền bằng lệnh
wall ~/Pictures/Wallpapers/emilia_dark.png

# Đổi ngẫu nhiên một hình nền trong thư mục
wallr
```
*(Hoặc click chuột phải vào bất kỳ ảnh nào trong Thunar $\rightarrow$ chọn **"Set as Caelestia Wallpaper"**)*.

## 🖥️ VMware Notes

If running on VMware Workstation, add these to `~/.config/caelestia/hypr-user.conf`:

```ini
env = LIBGL_ALWAYS_SOFTWARE,1
env = WLR_NO_HARDWARE_CURSORS,1
env = WLR_RENDERER_ALLOW_SOFTWARE,1
```

And start Caelestia Shell with:
```bash
export LIBGL_ALWAYS_SOFTWARE=1
caelestia shell
```

## 🙏 Credits

- [Caelestia Shell](https://github.com/caelestia-dots) — Material You desktop shell for Hyprland
- [Catppuccin](https://github.com/catppuccin) — Soothing pastel theme
- [Hyprland](https://hyprland.org/) — Dynamic tiling Wayland compositor
- [Doki Theme](https://github.com/doki-theme) — Anime wallpapers & stickers
