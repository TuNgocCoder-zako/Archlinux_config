local scheme = require("scheme.current")

hl.config({
    misc = {
        animate_manual_resizes       = true,
        animate_mouse_windowdragging = true,

        disable_hyprland_logo        = true,
        force_default_wallpaper      = 0,

        on_focus_under_fullscreen    = 2,
        allow_session_lock_restore   = true,
        middle_click_paste           = false,
        focus_on_activate            = true,
        session_lock_xray            = true,

        mouse_move_enables_dpms      = true,
        key_press_enables_dpms       = true,

        vrr                          = 0, -- Tắt VRR trên desktop (giữ 144Hz cố định để chống rung/giật ở góc màn hình)

        background_color             = "rgb(" .. scheme.surfaceContainer .. ")",
    },

    render = {
        direct_scanout               = 0, -- Tắt direct scanout để tránh xung đột với các góc bo màn hình của Caelestia
    },

    debug = {
        error_position = 1
    }
})
