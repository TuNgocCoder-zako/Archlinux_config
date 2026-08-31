-- ╔══════════════════════════════════════════════════╗
-- ║  Caelestia Shell — User Variables                ║
-- ║  Arch Linux + Hyprland + Material You            ║
-- ╚══════════════════════════════════════════════════╝

local scheme = require("scheme.current")

return {
    -------------------
    ----- HYPRLAND -----
    -------------------

    -- Apps
    terminal            = "foot",
    browser             = "firefox",
    editor              = "nvim",
    fileExplorer        = "thunar",
    audioSettings       = "pavucontrol",

    -- Blur (enable on bare metal, disable for VMware)
    blurEnabled         = true,
    blurSpecialWs       = false,
    blurPopups          = true,
    blurInputMethods    = true,
    blurSize            = 8,
    blurPasses          = 2,
    blurXray            = false,

    -- Window styling
    windowOpacity       = 0.95,
    windowRounding      = 15,
    windowBorderSize    = 1,

    -------------------
    ----- KEYBINDS -----
    -------------------

    -- Custom keybinds (additions to Caelestia defaults)
    kbTerminal          = { "SUPER + Return", "SUPER + T", "ALT + Return" },
    kbLauncher          = { "SUPER + D", "ALT + D", "SUPER + SUPER_L" },
    kbCloseWindow       = { "SUPER + Q", "ALT + Q" },
    kbFileExplorer      = { "SUPER + E", "ALT + E" },
    kbShowSidebar       = { "SUPER + N", "ALT + N" },
}
