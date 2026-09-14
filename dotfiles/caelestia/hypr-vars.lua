return {
    -- Apps
    terminal                   = "kitty",
    browser                    = "brave",
    editor                     = "nvim",
    fileExplorer               = "thunar",
    audioSettings              = "pavucontrol",

    -- Blur
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

    -- Apps (Keybinds)
    kbTerminal                 = { "SUPER + Return", "SUPER + T", "ALT + Return" },
    kbFileExplorer             = { "SUPER + E", "ALT + E" },

    -- Misc (Keybinds)
    kbShowSidebar              = { "SUPER + N", "ALT + N" },

    -- Custom
    kbLauncher                 = { "SUPER_L", "SUPER_R", "SUPER + SUPER_L", "SUPER + SUPER_R", "ALT + D" },

    -- Special Workspaces (Keybinds)
    kbMusicWs                  = { "SUPER + M", "ALT + M" },
    kbCommunicationWs          = { "SUPER + Z", "ALT + Z" },
}
