# 🌸 Arch Linux + Hyprland + Caelestia Shell — Dotfiles

Modern Arch Linux dotfiles with **Caelestia Shell** (Material You dynamic theming), **Hyprland** compositor, and anime aesthetics.

## Features

- **Caelestia Shell** — Material You desktop shell with dynamic wallpaper-based theming
- **Hyprland** — Wayland tiling compositor with smooth animations
- **GPU Auto-Detection** — Automatic NVIDIA / AMD / Intel / VMware driver setup
- **Modular Installer** — Choose `--minimal`, `--rice`, `--full`, or `--dev` profiles
- **Config Backup** — Automatic backup of existing configs before overwriting
- **System Health Check** — `./check.sh` verifies all components

## Requirements

- **Arch Linux** installed via `archinstall` (Minimal profile, UEFI, PipeWire, NetworkManager)
- Internet connection
- Non-root user with sudo access

## Installation

```bash
git clone https://github.com/TuNgocCoder-zako/Archlinux_config.git
cd Archlinux_config
chmod +x install.sh check.sh
./install.sh
```

### Install Profiles

| Flag | Description |
|------|-------------|
| *(none)* | Interactive — choose profile at runtime |
| `--minimal` | Core only: Hyprland, Foot, Fish, PipeWire, etc. |
| `--rice` | Core + theming: Cava, Fastfetch, Waypaper, etc. |
| `--full` | Everything including Firefox and dev tools |
| `--dev` | Core + development tools (Python, Rust, ripgrep, etc.) |

### Post-Install

1. Log out and log back in (or reboot)
2. Set your wallpaper:
   ```bash
   caelestia wallpaper -f ~/Pictures/Wallpapers/emilia_dark.png
   ```
3. Run health check:
   ```bash
   ./check.sh
   ```

## Structure

```
.
├── install.sh                 # Modular installer with profiles
├── check.sh                   # System health check
├── LICENSE                    # MIT License
├── .gitignore
│
├── packages/                  # Package lists (one per profile)
│   ├── core.txt               # Essential system packages
│   ├── rice.txt               # Theming & aesthetic packages
│   ├── optional.txt           # Nice to have (Firefox, etc.)
│   └── dev.txt                # Development tools
│
├── dotfiles/
│   ├── hypr/
│   │   ├── env.conf           # Common environment variables
│   │   ├── env-nvidia.conf    # NVIDIA-specific env vars
│   │   ├── env-amd.conf       # AMD-specific env vars
│   │   ├── env-intel.conf     # Intel-specific env vars
│   │   ├── env-vmware.conf    # VMware-specific env vars
│   │   └── hypridle.conf      # Auto-lock & screen off
│   ├── caelestia/
│   │   ├── hypr-vars.lua      # Caelestia variables & keybinds
│   │   └── hypr-user.conf     # Hyprland user overrides
│   ├── foot/foot.ini          # Terminal (Catppuccin Mocha)
│   ├── fuzzel/fuzzel.ini      # App launcher
│   ├── fish/config.fish       # Fish shell config
│   ├── cava/config            # Audio visualizer
│   ├── fastfetch/config.jsonc # System info display
│   ├── mako/config            # Notification daemon
│   ├── gtk-3.0/settings.ini   # GTK theme settings
│   ├── waypaper/config.ini    # Wallpaper picker
│   └── Thunar/uca.xml         # Right-click wallpaper action
│
└── scripts/
    ├── set-wallpaper          # Set wallpaper + persist
    └── restore-wallpaper      # Restore wallpaper on boot
```

## Key Bindings

| Key | Action |
|-----|--------|
| `Super + T` / `Super + Return` | Terminal (Foot) |
| `Super + D` | App launcher (Fuzzel) |
| `Super + V` | Clipboard history (Cliphist) |
| `Super + C` | Audio visualizer (Cava) |
| `Super + I` | System info (Fastfetch) |
| `Super + N` | Sidebar / Control Center |
| `Super + E` | File manager (Thunar) |
| `Super + W` | Browser (Firefox) |
| `Super + L` | Lock screen |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Alt + S` | Screenshot to clipboard |
| `Super + Shift + S` | Screenshot + annotation (Swappy) |
| `Super + Shift + W` | Wallpaper picker (Waypaper) |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + Q` | Exit Hyprland |

## GPU Support

The installer **auto-detects** your GPU and installs appropriate drivers:

| GPU | Driver | Env Profile |
|-----|--------|-------------|
| NVIDIA | `nvidia-dkms`, `nvidia-utils`, `egl-wayland` | `env-nvidia.conf` |
| AMD | `vulkan-radeon`, `libva-mesa-driver` | `env-amd.conf` |
| Intel | `vulkan-intel`, `intel-media-driver` | `env-intel.conf` |
| VMware / Generic | Mesa (default) | `env-vmware.conf` |

### NVIDIA Optimus (Hybrid Laptop)

```bash
# Run apps on dedicated NVIDIA GPU
prime-run blender
prime-run steam
```

## VMware Notes

The installer automatically applies VMware-compatible settings when no discrete GPU is detected. If running manually, the `env-vmware.conf` profile enables software rendering.

## Wallpaper

```bash
# Set wallpaper via CLI
wall ~/Pictures/Wallpapers/emilia_dark.png

# Random wallpaper
wallr

# Or right-click any image in Thunar → "Set as Caelestia Wallpaper"
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Black screen after login | Check GPU env profile: `cat ~/.config/hypr/env-gpu.conf` |
| No sound | Run `wpctl status` and ensure PipeWire is running |
| Cursor invisible | Ensure cursor theme is installed: `pacman -Qi bibata-cursor-theme-bin` |
| Wallpaper not restoring | Check `~/.cache/current_wallpaper` exists |
| SDDM not showing | `sudo systemctl enable sddm` and reboot |
| Missing components | Run `./check.sh` to diagnose |

## Credits

- [Caelestia Shell](https://github.com/caelestia-dots) — Material You desktop shell
- [Hyprland](https://hyprland.org/) — Dynamic tiling Wayland compositor
- [Catppuccin](https://github.com/catppuccin) — Soothing pastel theme
- [Keyitdev Astronaut](https://github.com/Keyitdev/sddm-astronaut-theme) — SDDM theme
- [Doki Theme](https://github.com/doki-theme) — Anime wallpapers

## License

[MIT](LICENSE)
