hl.config({
    animations = {
        enabled = true,
    },
})

-- ══════════════════════════════════════════════════════════════
-- Bezier Curves — Chuẩn showcase mượt mà, đàn hồi trên 144Hz
-- ══════════════════════════════════════════════════════════════

-- Fluent decel: Giảm tốc mềm mại tự nhiên
hl.curve("fluent_decel",      { type = "bezier", points = { { 0.05, 0.9 }, { 0.1,  1.0  } } })

-- EaseOutExpo: Cực kỳ êm ái, trôi lướt và hãm nhẹ (dùng cho fade, workspace)
hl.curve("easeOutExpo",       { type = "bezier", points = { { 0.16, 1.0 }, { 0.3,  1.0  } } })

-- EaseOutCirc: Đóng cửa sổ dứt khoát nhưng không bị khựng
hl.curve("easeOutCirc",       { type = "bezier", points = { { 0.0,  0.55}, { 0.45, 1.0  } } })

-- Bounce: Đường cong kinh điển tạo độ nảy nhẹ (elastic overshoot) khi bung cửa sổ
hl.curve("bounce",            { type = "bezier", points = { { 0.1,  1.12}, { 0.15, 1.02 } } })

-- Smooth move: Di chuyển cửa sổ trượt bám tay
hl.curve("smooth_move",       { type = "bezier", points = { { 0.2,  0.95}, { 0.25, 1.0  } } })

-- Workspace bezier: Lướt chuyển workspace như dải lụa
hl.curve("workspaces_bezier", { type = "bezier", points = { { 0.2,  0.9 }, { 0.25, 1.0  } } })

-- Special workspace: Slide từ trên xuống êm ái
hl.curve("specialWorkSwitch", { type = "bezier", points = { { 0.1,  0.9 }, { 0.15, 1.0  } } })

-- Linear: Dùng cho animation lặp viền (nếu có)
hl.curve("linear",            { type = "bezier", points = { { 0.0,  0.0 }, { 1.0,  1.0  } } })


-- ══════════════════════════════════════════════════════════════
-- Window Animations — Mở/Đóng/Di chuyển cửa sổ sống động
-- ══════════════════════════════════════════════════════════════

-- Mở cửa sổ: popin 82% với độ nảy bounce nhẹ (showcase style)
hl.animation({ leaf = "windows",     enabled = true, speed = 3.6, bezier = "bounce",      style = "popin 82%" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3.6, bezier = "bounce",      style = "popin 82%" })

-- Đóng cửa sổ: êm dịu, biến mất gọn gàng
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2.4, bezier = "easeOutCirc", style = "popin 88%" })

-- Di chuyển / Tiling resize: mượt mà, không bị lag mắt
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3.5, bezier = "smooth_move" })


-- ══════════════════════════════════════════════════════════════
-- Layer Animations — Thanh Bar / Launcher / Panels trượt ra vào
-- ══════════════════════════════════════════════════════════════

hl.animation({ leaf = "layers",         enabled = true, speed = 3.2, bezier = "fluent_decel", style = "slide" })
hl.animation({ leaf = "layersIn",       enabled = true, speed = 3.2, bezier = "fluent_decel", style = "slide" })
hl.animation({ leaf = "layersOut",      enabled = true, speed = 2.2, bezier = "easeOutCirc",  style = "slide" })
hl.animation({ leaf = "fadeLayers",     enabled = true, speed = 3.0, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeLayersIn",   enabled = true, speed = 3.0, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeLayersOut",  enabled = true, speed = 2.2, bezier = "easeOutCirc" })


-- ══════════════════════════════════════════════════════════════
-- Workspace Animations — Chuyển cảnh workspace mượt mà
-- ══════════════════════════════════════════════════════════════

hl.animation({ leaf = "workspaces",      enabled = true, speed = 3.6, bezier = "workspaces_bezier", style = "slide" })

hl.animation({
    leaf    = "specialWorkspace",
    enabled = true,
    speed   = 3.0,
    bezier  = "specialWorkSwitch",
    style   = "slidefadevert 15%"
})


-- ══════════════════════════════════════════════════════════════
-- Fade Animations — Focus/unfocus, bóng, làm tối nền
-- ══════════════════════════════════════════════════════════════

hl.animation({ leaf = "fade",       enabled = true, speed = 3.0, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeIn",     enabled = true, speed = 3.0, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeOut",    enabled = true, speed = 2.2, bezier = "easeOutCirc" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 2.8, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 3.0, bezier = "easeOutExpo" })
hl.animation({ leaf = "fadeDim",    enabled = true, speed = 2.8, bezier = "easeOutExpo" })


-- ══════════════════════════════════════════════════════════════
-- Border Animations — Viền cửa sổ
-- ══════════════════════════════════════════════════════════════

hl.animation({ leaf = "border",      enabled = true, speed = 3.0, bezier = "fluent_decel" })
hl.animation({ leaf = "borderangle", enabled = false })
