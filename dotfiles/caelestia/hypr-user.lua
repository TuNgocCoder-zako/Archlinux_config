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

    -- Bluetooth (nguồn được quản lý tự động theo sạc AC)
    hl.exec_cmd("blueman-applet")
end)

--------------------------------------------------------------------------------
-- 3. Custom Keybindings
--------------------------------------------------------------------------------
-- Bluetooth Manager
hl.bind("SUPER + B", hl.dsp.exec_cmd("blueman-manager"))
hl.bind("ALT + B", hl.dsp.exec_cmd("blueman-manager"))

-- ASUS TUF Keyboard — Function Keys F1-F12 (Khớp 100% biểu tượng in trên bàn phím)
-- F1: Mute Audio
hl.bind("SUPER + F1", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))

-- F2: Volume Down
hl.bind("SUPER + F2", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-"))

-- F3: Volume Up
hl.bind("SUPER + F3", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"))

-- F4: Mic Mute
hl.bind("SUPER + F4", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))

-- F5 (Biểu tượng Cánh quạt ASUS Fan): Quạt tản nhiệt & Chế độ hiệu năng
hl.bind("XF86Launch4", hl.dsp.exec_cmd(home .. "/.local/bin/asus-fan-toggle"), { locked = true })
hl.bind("SUPER + F5", hl.dsp.exec_cmd(home .. "/.local/bin/asus-fan-toggle"))
hl.bind("ALT + F5", hl.dsp.exec_cmd(home .. "/.local/bin/asus-fan-toggle"))
hl.bind("SUPER + 5", hl.dsp.exec_cmd(home .. "/.local/bin/asus-fan-toggle"))
hl.bind("ALT + 5", hl.dsp.exec_cmd(home .. "/.local/bin/asus-fan-toggle"))

-- F6 (Biểu tượng Snipping Tool / Kéo cắt ảnh): Chụp vùng màn hình & Chỉnh sửa
hl.bind("XF86Launch1", hl.dsp.exec_cmd('grim -g "$(slurp -d)" - | swappy -f -'), { locked = true })
hl.bind("XF86SelectiveScreenshot", hl.dsp.exec_cmd('grim -g "$(slurp -d)" - | swappy -f -'), { locked = true })
hl.bind("SUPER + F6", hl.dsp.exec_cmd('grim -g "$(slurp -d)" - | swappy -f -'))
hl.bind("ALT + F6", hl.dsp.exec_cmd('grim -g "$(slurp -d)" - | swappy -f -'))

-- F7 (Biểu tượng Mặt trời nhỏ): Giảm độ sáng màn hình
hl.bind("SUPER + F7", hl.dsp.exec_cmd("brightnessctl s 5%-"))
hl.bind("ALT + F7", hl.dsp.exec_cmd("brightnessctl s 5%-"))

-- F8 (Biểu tượng Mặt trời lớn): Tăng độ sáng màn hình
hl.bind("SUPER + F8", hl.dsp.exec_cmd("brightnessctl s 5%+"))
hl.bind("ALT + F8", hl.dsp.exec_cmd("brightnessctl s 5%+"))

-- F9 (Biểu tượng Màn hình chiếu Project): Quản lý / Xuất màn hình ngoài
hl.bind("XF86Display", hl.dsp.exec_cmd(home .. "/.local/bin/display-toggle"), { locked = true })
hl.bind("SUPER + F9", hl.dsp.exec_cmd(home .. "/.local/bin/display-toggle"))
hl.bind("ALT + F9", hl.dsp.exec_cmd(home .. "/.local/bin/display-toggle"))

-- F10 (Biểu tượng Touchpad có gạch chéo): Bật / Khóa bàn di chuột
hl.bind("XF86TouchpadToggle", hl.dsp.exec_cmd(home .. "/.local/bin/touchpad-toggle"), { locked = true })
hl.bind("SUPER + F10", hl.dsp.exec_cmd(home .. "/.local/bin/touchpad-toggle"))
hl.bind("ALT + F10", hl.dsp.exec_cmd(home .. "/.local/bin/touchpad-toggle"))

-- F11 (Biểu tượng Trăng khuyết Zzz): Chế độ ngủ (Sleep / Suspend)
hl.bind("XF86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true })
hl.bind("SUPER + F11", hl.dsp.exec_cmd("systemctl suspend"))
hl.bind("ALT + F11", hl.dsp.exec_cmd("systemctl suspend"))

-- F12 (Biểu tượng Máy bay): Bật / Tắt chế độ máy bay (Airplane mode)
hl.bind("XF86RFKill", hl.dsp.exec_cmd(home .. "/.local/bin/airplane-mode-toggle"), { locked = true })
hl.bind("SUPER + F12", hl.dsp.exec_cmd(home .. "/.local/bin/airplane-mode-toggle"))
hl.bind("ALT + F12", hl.dsp.exec_cmd(home .. "/.local/bin/airplane-mode-toggle"))

-- Phím mũi tên (Arrow keys): Đèn bàn phím & Aura RGB (Khớp biểu tượng trên phím)
-- Fn + Up / Down (Icon bóng đèn): Tăng / Giảm độ sáng đèn nền bàn phím
hl.bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd(home .. "/.local/bin/asus-kbd-toggle up"), { locked = true })
hl.bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd(home .. "/.local/bin/asus-kbd-toggle down"), { locked = true })
hl.bind("SUPER + ALT + Up", hl.dsp.exec_cmd(home .. "/.local/bin/asus-kbd-toggle up"))
hl.bind("SUPER + ALT + Down", hl.dsp.exec_cmd(home .. "/.local/bin/asus-kbd-toggle down"))

-- Fn + Left / Right (Icon AURA): Chuyển đổi chế độ màu Aura RGB
hl.bind("XF86Launch3", hl.dsp.exec_cmd(home .. "/.local/bin/asus-kbd-toggle mode"), { locked = true })
hl.bind("XF86Launch2", hl.dsp.exec_cmd(home .. "/.local/bin/asus-kbd-toggle mode"), { locked = true })
hl.bind("SUPER + ALT + Left", hl.dsp.exec_cmd(home .. "/.local/bin/asus-kbd-toggle mode"))
hl.bind("SUPER + ALT + Right", hl.dsp.exec_cmd(home .. "/.local/bin/asus-kbd-toggle mode"))

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

-- Voice AI Alexa Assistant (Trigger & Stop - chuyển sang SUPER + A theo yêu cầu)
hl.bind("SUPER + A", hl.dsp.exec_cmd(home .. "/.local/bin/alexa-trigger"))
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd(home .. "/.local/bin/alexa-stop"))

-- AI Assistant drawer
hl.bind("ALT + A", hl.dsp.exec_cmd("caelestia shell drawers toggleTab sidebar ai"))

-- Multitasking (Workspace Overview & Window Switcher)
hl.bind("SUPER + Tab", hl.dsp.global("caelestia:workspaceOverview"))
hl.bind("SUPER + Grave", hl.dsp.global("caelestia:windowSwitcher"))

--------------------------------------------------------------------------------
-- 4. Window Rules
--------------------------------------------------------------------------------
hl.window_rule({ match = { class = "com.asus.tuf.control" }, float = true, size = "540 700", center = true })
hl.window_rule({ match = { class = "floating-term" }, float = true, size = "800 500", center = true })
hl.window_rule({ match = { class = "cava-term" }, float = true, size = "720 280", center = true, opacity = "0.90 0.80 override" })
