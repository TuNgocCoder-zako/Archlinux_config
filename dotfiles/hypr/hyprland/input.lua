local vars = require("variables")

hl.config({
    input = {
        kb_layout          = "us",
        numlock_by_default = false,
        repeat_delay       = 250,
        repeat_rate        = 35,
        focus_on_close     = 1,
        sensitivity        = vars.touchpadSensitivity or 0.35,

        touchpad           = {
            natural_scroll       = true,
            disable_while_typing = vars.touchpadDisableTyping,
            scroll_factor        = vars.touchpadScrollFactor or 0.6,
        },
    },

    binds = {
        scroll_event_delay = 0,
    },

    cursor = {
        hotspot_padding     = 1,
        no_hardware_cursors = false,
        enable_hyprcursor   = false,
    },
})

hl.device({
    name        = "elan1203:00-04f3:307a-touchpad",
    sensitivity = vars.touchpadSensitivity or 0.35,
})
hl.device({
    name        = "elan1203:00-04f3:307a-mouse",
    sensitivity = vars.touchpadSensitivity or 0.35,
})
