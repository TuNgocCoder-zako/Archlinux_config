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
│   │   ├── hyprlock.conf         # Anime lock screen
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

## ⌨️ Key Bindings (Caelestia Defaults)

| Key | Action |
|-----|--------|
| `Super + T` | Open Terminal (Foot) |
| `Super + Super_L` | App Launcher |
| `Super + N` | Toggle Sidebar / Control Center |
| `Super + K` | Show Panels |
| `Super + Q` | Close window |
| `Super + E` | File manager (Thunar) |
| `Super + W` | Open Browser (Firefox) |
| `Super + L` | Lock screen |
| `Super + F` | Fullscreen |
| `Alt + Space` | Toggle floating |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + Q` | Exit Hyprland |
| `Print` | Screenshot |
| `Super + Shift + S` | Screenshot (region) |
| `Super + V` | Clipboard history |

### Custom Additions

| Key | Action |
|-----|--------|
| `Super + Enter` | Open Terminal (added) |
| `Super + D` | Fuzzel launcher (added) |
| `Alt + S` | Screenshot region to clipboard |

## 🎨 Wallpaper & Dynamic Theming

Caelestia Shell automatically extracts colors from your wallpaper and applies them system-wide (bar, control center, terminal, launcher).

```bash
# Set wallpaper via CLI
caelestia wallpaper -f ~/Pictures/Wallpapers/your-image.png

# Random wallpaper from directory
caelestia wallpaper -r ~/Pictures/Wallpapers/
```

Or right-click any image in Thunar → "🌸 Set as Caelestia Wallpaper"

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
