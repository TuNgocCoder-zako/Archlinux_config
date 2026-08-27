# Hyprland Anime Rice — Dotfiles
# Catppuccin Mocha + VMware Optimized

```
  ╔═══════════════════════════════════════════╗
  ║                                           ║
  ║   🌸 Anime Hyprland Rice 🌸              ║
  ║   Arch Linux + Catppuccin Mocha           ║
  ║   VMware Workstation Edition              ║
  ║                                           ║
  ╚═══════════════════════════════════════════╝
```

## Structure

```
.
├── install.sh              # Automated installer
├── dotfiles/
│   ├── hypr/
│   │   ├── hyprland.conf   # Main Hyprland config
│   │   ├── env.conf        # Environment variables (VMware)
│   │   ├── keybinds.conf   # All keybindings
│   │   ├── hyprlock.conf   # Lock screen (anime style)
│   │   └── hypridle.conf   # Auto-lock / screen off
│   ├── waybar/
│   │   ├── config.jsonc    # Waybar modules (Kanji workspaces)
│   │   └── style.css       # Waybar style (Catppuccin)
│   ├── foot/
│   │   └── foot.ini        # Terminal config
│   ├── rofi/
│   │   └── anime.rasi      # App launcher theme
│   ├── swaync/
│   │   ├── config.json     # Notification center
│   │   └── style.css       # Notification style
│   ├── gtk-3.0/
│   │   └── settings.ini    # GTK theme settings
│   ├── fastfetch/
│   │   └── config.jsonc    # System info display
│   ├── cava/
│   │   └── config          # Audio visualizer
│   ├── starship.toml       # Shell prompt
│   └── .zshrc              # Zsh configuration
└── README.md
```

## Quick Install

1. Install Arch Linux via `archinstall` (Minimal profile, UEFI, PipeWire, NetworkManager)
2. Copy this folder to the Arch VM
3. Run the installer:

```bash
chmod +x install.sh
./install.sh
```

4. Download anime wallpapers to `~/Pictures/Wallpapers/`
5. Log out, log back in, and run `Hyprland` from TTY

## Key Bindings

| Key | Action |
|-----|--------|
| `Super + Enter` | Terminal (foot) |
| `Super + D` | App launcher (rofi) |
| `Super + Q` | Close window |
| `Super + E` | File manager (thunar) |
| `Super + W` | Wallpaper picker |
| `Super + V` | Toggle floating |
| `Super + F` | Fullscreen |
| `Super + L` | Lock screen |
| `Super + N` | Notifications |
| `Super + Shift+V` | Clipboard history |
| `Print` | Screenshot (region) |
| `Super + 1-9` | Switch workspace |
| `Super + Shift+Q` | Exit Hyprland |

## Theme: Catppuccin Mocha

All configs use the Catppuccin Mocha color palette for a consistent, anime-aesthetic look.

## VMware Notes

- Blur is disabled (too heavy for VMware)
- Animations are lightweight
- `WLR_RENDERER_ALLOW_SOFTWARE=1` enables software rendering
- `WLR_NO_HARDWARE_CURSORS=1` fixes invisible cursor
- Use `foot` instead of `kitty` (kitty crashes on VMware)
