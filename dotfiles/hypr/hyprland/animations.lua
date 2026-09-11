hl.config({
    animations = {
        enabled = true,
    },
})

-- 144Hz High-Refresh Tuned Curves
hl.curve("fluent_decel", { type = "bezier", points = { { 0.1, 1 }, { 0, 1 } } })
hl.curve("popin_overshoot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.04 } } })
hl.curve("md3_decel", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1 } } })
hl.curve("md3_accel", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("easeIn", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })
hl.curve("fluid", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1 } } })
hl.curve("workspaces_bezier", { type = "bezier", points = { { 0.12, 0.96 }, { 0.15, 1 } } })
hl.curve("specialWorkSwitch", { type = "bezier", points = { { 0.1, 0.9 }, { 0.1, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

-- Animation configs tuned for 144Hz buttery smoothness
hl.animation({ leaf = "windows", enabled = true, speed = 2.8, bezier = "popin_overshoot", style = "popin 85%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.8, bezier = "popin_overshoot", style = "popin 85%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.0, bezier = "easeIn", style = "popin 85%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.6, bezier = "fluent_decel" })

hl.animation({ leaf = "layers", enabled = true, speed = 2.6, bezier = "fluent_decel", style = "slide" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 2.6, bezier = "fluent_decel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2.0, bezier = "easeIn", style = "slide" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 2.5, bezier = "fluent_decel" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2.5, bezier = "fluent_decel" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2.0, bezier = "easeIn" })

-- Workspaces: Chuyển cảnh mượt mà chuẩn 144Hz với hiệu ứng trượt + mờ dần (slidefade 20%)
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.8, bezier = "workspaces_bezier", style = "slidefade 20%" })

hl.animation({
    leaf    = "specialWorkspace",
    enabled = true,
    speed   = 2.8,
    bezier  = "specialWorkSwitch",
    style   = "slidefadevert 15%"
})

hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "fluent_decel" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2.5, bezier = "fluent_decel" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.0, bezier = "easeIn" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 2.5, bezier = "fluent_decel" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 2.5, bezier = "fluent_decel" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 2.5, bezier = "fluent_decel" })

hl.animation({ leaf = "border", enabled = true, speed = 2.8, bezier = "fluent_decel" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 35, bezier = "linear", style = "loop" })
