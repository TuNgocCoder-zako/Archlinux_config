local fn = require("utils.functions")

-- Kiểm tra xem tiến trình của cửa sổ có xuất phát từ Dock hay không
local function is_dock_launched(pid)
    if not pid or pid <= 1 then return false end

    local curr = pid
    for _ = 1, 5 do
        -- 1. Kiểm tra biến môi trường LAUNCHED_FROM_DOCK
        local env_file = io.open("/proc/" .. curr .. "/environ", "rb")
        if env_file then
            local data = env_file:read("*a")
            env_file:close()
            if data and data:find("LAUNCHED_FROM_DOCK=1", 1, true) then
                return true
            end
        end

        -- 2. Kiểm tra Parent Process có phải là nwg-dock-hyprland không
        local stat_file = io.open("/proc/" .. curr .. "/stat", "r")
        if stat_file then
            local line = stat_file:read("*l")
            stat_file:close()
            local comm, ppid = line and line:match("%d+ %(?(.-)%)? %a (%d+)")
            if comm and comm:find("nwg%-dock", 1) then
                return true
            end
            if not ppid or ppid == "0" or ppid == "1" or ppid == tostring(curr) then
                break
            end
            curr = tonumber(ppid) or 0
        else
            break
        end
    end
    return false
end

-- Lắng nghe sự kiện cửa sổ mới mở
hl.on("window.open", function(w)
    if not w or not w.pid or not w.address then return end
    if w.class == "" or w.class == "hyprpicker" then return end

    if is_dock_launched(w.pid) then
        -- Bỏ qua nếu là hộp thoại (file picker, save dialog, properties)
        local is_dialog = false
        if w.title and (
            w.title:find("Select", 1, true) or
            w.title:find("Open", 1, true) or
            w.title:find("Save As", 1, true) or
            w.title:find("Properties", 1, true)
        ) then
            is_dialog = true
        end

        if not is_dialog then
            -- Chuyển sang Floating (cửa sổ nổi xếp chồng)
            hl.dispatch(hl.dsp.window.float({ action = "set", window = "address:" .. w.address }))

            -- Phóng to theo chuẩn Mac/Win (97% width, 93% height - chừa mép bo góc kính và dock)
            local sz = fn.resize_by_screen(97, 93)
            if sz then
                sz.window = w
                hl.dispatch(hl.dsp.window.resize(sz))
            end

            -- Căn giữa màn hình và đưa lên lớp trên cùng (Top Z-order)
            hl.dispatch(hl.dsp.window.center({ window = "address:" .. w.address }))
            hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = "address:" .. w.address }))
        end
    end
end)

return {
    is_dock_launched = is_dock_launched,
}
