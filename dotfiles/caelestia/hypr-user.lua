-- Caelestia Shell — User Hyprland Configuration (Lua)

local home = os.getenv("HOME")

--------------------------------------------------------------------------------
-- 1. Input Method & Toolkit Environment Variables
--------------------------------------------------------------------------------
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
hl.env("GLFW_IM_MODULE", "ibus")

--------------------------------------------------------------------------------
-- 2. Autostart
--------------------------------------------------------------------------------
hl.on("hyprland.start", function()
    -- D-Bus / systemd activation environment
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XMODIFIERS QT_IM_MODULE")

    -- Vietnamese input method (Fcitx5)
    hl.exec_cmd("fcitx5 -d")

    -- Idle daemon & wallpaper
    hl.exec_cmd("hypridle")
    hl.exec_cmd(home .. "/.local/bin/restore-wallpaper")
end)

--------------------------------------------------------------------------------
-- 3. Custom Keybindings
--------------------------------------------------------------------------------
-- ASUS TUF fan profile switching
hl.bind("XF86Launch4", hl.dsp.exec_cmd(home .. "/.local/bin/asus-fan-toggle"))
hl.bind("SUPER + F5", hl.dsp.exec_cmd(home .. "/.local/bin/asus-fan-toggle"))
hl.bind("ALT + F5", hl.dsp.exec_cmd(home .. "/.local/bin/asus-fan-toggle"))

-- Screenshots
hl.bind("ALT + S", hl.dsp.exec_cmd('grim -g "$(slurp -d)" - | wl-copy && notify-send "📸 Screenshot" "Đã copy vào clipboard"'))
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp -d)" - | swappy -f -'))

-- Terminals (Floating / Cava)
hl.bind("SUPER + I", hl.dsp.exec_cmd("kitty --class floating-term --hold fastfetch"))
hl.bind("ALT + I", hl.dsp.exec_cmd("kitty --class floating-term --hold fastfetch"))
hl.bind("SUPER + C", hl.dsp.exec_cmd("kitty --class cava-term cava"))
hl.bind("ALT + C", hl.dsp.exec_cmd("kitty --class cava-term cava"))

-- Wallpaper tools (Caelestia native animated wallpaper selector & random switch)
hl.bind("SUPER + SHIFT + W", hl.dsp.global("caelestia:wallpaper"))
hl.bind("ALT + W", hl.dsp.global("caelestia:wallpaper"))
hl.bind("SUPER + CTRL + W", hl.dsp.exec_cmd("caelestia wallpaper -r"))

-- Lock screen
hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"))

-- AI Assistant drawer
hl.bind("SUPER + A", hl.dsp.exec_cmd("caelestia shell drawers toggleTab sidebar ai"))
hl.bind("ALT + A", hl.dsp.exec_cmd("caelestia shell drawers toggleTab sidebar ai"))

--------------------------------------------------------------------------------
-- 4. Window Rules
--------------------------------------------------------------------------------
hl.window_rule({ match = { class = "com.asus.tuf.control" }, float = true, size = "540 700", center = true })
hl.window_rule({ match = { class = "floating-term" }, float = true, size = "800 500", center = true })
hl.window_rule({ match = { class = "cava-term" }, float = true, size = "720 280", center = true, opacity = "0.90 0.80 override" })
