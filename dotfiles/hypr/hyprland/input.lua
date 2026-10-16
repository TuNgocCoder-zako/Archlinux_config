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

-- Touchpad toggle state check (hỗ trợ Super + F10 / asus-tuf-control)
local runtime_dir = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
local is_tp_disabled = false
local f = io.open(runtime_dir .. "/touchpad-disabled", "r") or io.open("/tmp/touchpad-disabled", "r")
if f then
    is_tp_disabled = true
    f:close()
end

hl.device({
    name        = "elan1203:00-04f3:307a-touchpad",
    sensitivity = vars.touchpadSensitivity or 0.35,
    enabled     = not is_tp_disabled,
})
hl.device({
    name        = "elan1203:00-04f3:307a-mouse",
    sensitivity = vars.touchpadSensitivity or 0.35,
    enabled     = not is_tp_disabled,
})

