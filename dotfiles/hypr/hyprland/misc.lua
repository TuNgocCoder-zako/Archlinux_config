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

        -- Tắt VRR (giữ 144Hz cố định chống flicker khi đọc tài liệu/viết code)
        vrr                          = 0,

        background_color             = "rgb(" .. scheme.surfaceContainer .. ")",
    },

    render = {
        direct_scanout         = 1,
        new_render_scheduling  = true,
    },

    debug = {
        error_position = 1
    }
})
