return {
    -- Apps
    terminal                   = "kitty",
    browser                    = "firefox",
    fileExplorer               = "thunar",

    -- Touchpad
    touchpadSensitivity        = 0.35,
    touchpadScrollFactor       = 0.65,
    touchpadDisableTyping      = false,
    workspaceSwipeFingers      = 3,

    -- Blur
    blurEnabled                = false,
    blurSpecialWs              = true,
    blurPopups                 = true,
    blurInputMethods           = true,
    blurSize                   = 6,
    blurPasses                 = 2,
    blurXray                   = true,

    -- Shadow
    shadowEnabled              = true,
    shadowRenderPower          = 3,

    -- Window styling
    windowOpacity              = 1,
    windowRounding             = 15,
    windowBorderSize           = 1,

    -- Window Action
    kbCloseWindow              = { "SUPER + Q", "ALT + Q" },

    -- Special workspaces toggles
    kbMusicWs                  = "",
    kbCommunicationWs          = "",
    kbTodoWs                   = "",

    -- Apps (Keybinds)
    kbTerminal                 = { "SUPER + Return", "SUPER + T", "ALT + Return" },
    kbBrowser                  = "SUPER + W",
    kbEditor                   = "",
    kbFileExplorer             = { "SUPER + E", "ALT + E" },

    -- Misc (Keybinds)
    kbShowSidebar              = { "SUPER + N", "ALT + N" },

    -- Custom
    kbAudioSettings            = "",
    kbLauncher                 = { "SUPER_L", "SUPER_R", "SUPER + SUPER_L", "SUPER + SUPER_R", "ALT + D" },
}
