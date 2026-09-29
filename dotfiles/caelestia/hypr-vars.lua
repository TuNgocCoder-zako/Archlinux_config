return {
    -- Apps (Chỉ giữ lại Terminal, Web Browser, Thunar File Explorer)
    terminal                   = "kitty",
    browser                    = "firefox",
    fileExplorer               = "thunar",

    -- Blur & Styling
    blurEnabled                = true,
    blurSpecialWs              = true,
    blurPopups                 = true,
    blurInputMethods           = true,
    blurSize                   = 6,
    blurPasses                 = 2,
    blurXray                   = true,

    -- Shadow
    shadowEnabled              = true,
    shadowRenderPower          = 2,

    -- Window styling
    windowOpacity              = 1,
    windowRounding             = 15,
    windowBorderSize           = 1,

    -- Window Action
    kbCloseWindow              = { "SUPER + Q", "ALT + Q" },

    -- Phím gán ứng dụng được giữ lại: Terminal, Web, Thunar
    kbTerminal                 = { "SUPER + Return", "SUPER + T", "ALT + Return" },
    kbBrowser                  = "SUPER + W",
    kbFileExplorer             = { "SUPER + E", "ALT + E" },

    -- Loại bỏ hoàn toàn các phím gán ứng dụng khác & ứng dụng gây xung đột/lỗi
    kbEditor                   = "",
    kbAudioSettings            = "",
    kbMusicWs                  = "",
    kbCommunicationWs          = "",
    kbTodoWs                   = "",

    -- Misc (Keybinds)
    kbShowSidebar              = { "SUPER + N", "ALT + N" },

    -- Caelestia Launcher
    kbLauncher                 = { "SUPER_L", "SUPER_R", "SUPER + SUPER_L", "SUPER + SUPER_R", "ALT + D" },
}
