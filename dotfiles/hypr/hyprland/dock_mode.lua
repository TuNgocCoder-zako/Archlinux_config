local fn = require("utils.functions")

-- Danh sách các cửa sổ đã được xử lý layout dock để tránh lặp lại
local handled_windows = {}

-- 1. Kiểm tra qua /proc/<pid>/environ hoặc PPID (bắt các app thông thường có kế thừa env)
local function is_dock_proc(pid)
    if not pid or pid <= 1 then return false end

    local curr = pid
    for _ = 1, 6 do
        local env_file = io.open("/proc/" .. curr .. "/environ", "rb")
        if env_file then
            local data = env_file:read("*a")
            env_file:close()
            if data and data:find("LAUNCHED_FROM_DOCK=1", 1, true) then
                return true
            end
        end

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

-- 2. Đọc tín hiệu nhấp Dock gần nhất (bắt trọn vẹn cả Electron, AppImage, daemon như Code, Zalo, Docker Desktop)
local function get_dock_launch_signal()
    local runtime_dir = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
    local f = io.open(runtime_dir .. "/nwg_dock_last_launch", "r")
    if not f then return nil end

    local content = f:read("*l")
    f:close()
    if not content then return nil end

    local ts, cmd = content:match("(%d+)%s*(.*)")
    if ts and cmd then
        local now = os.time()
        local diff = now - tonumber(ts)
        -- Tín hiệu hợp lệ trong vòng 15 giây kể từ khi click trên Dock
        if diff >= 0 and diff <= 15 then
            return { ts = tonumber(ts), cmd = cmd:lower() }
        end
    end
    return nil
end

local function consume_dock_signal()
    local runtime_dir = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
    os.remove(runtime_dir .. "/nwg_dock_last_launch")
end

-- 3. Khớp thông tin cửa sổ với lệnh vừa được khởi chạy từ Dock
local function matches_dock_cmd(cmd, cls, init_cls, title)
    cmd = (cmd or ""):lower()
    cls = (cls or ""):lower()
    init_cls = (init_cls or ""):lower()
    title = (title or ""):lower()

    if cmd == "" then return false end
    if cls == "" and init_cls == "" and title == "" then return false end

    -- Bảng đối chiếu từ khóa cho các ứng dụng đặc thù
    local app_patterns = {
        code   = { "code", "vscode", "visual studio code" },
        zalo   = { "zalo", "zalo-for-linux" },
        docker = { "docker", "docker desktop", "docker-desktop" },
        idea   = { "idea", "jetbrains" },
        studio = { "studio", "android-studio" },
        canva  = { "canva" },
        dbeaver= { "dbeaver" },
        spotify= { "spotify" },
        thunar = { "thunar" },
        kitty  = { "kitty" },
        firefox= { "firefox" },
    }

    for key, aliases in pairs(app_patterns) do
        if cmd:find(key, 1, true) then
            for _, alias in ipairs(aliases) do
                if cls:find(alias, 1, true) or init_cls:find(alias, 1, true) or title:find(alias, 1, true) then
                    return true
                end
            end
        end
    end

    -- Khớp tổng quát theo tên binary
    local bin = cmd:match("([^/%s]+)") or cmd
    bin = bin:gsub("%.%w+$", "") -- Bỏ phần đuôi nếu có
    if #bin >= 3 then
        if cls:find(bin, 1, true) or init_cls:find(bin, 1, true) or title:find(bin, 1, true) then
            return true
        end
    end

    return false
end

-- 4. Áp dụng chuẩn Mac/Windows: Cửa sổ nổi toàn màn hình (97% x 93%), căn giữa, xếp chồng lên trên cùng
local function apply_dock_layout(w)
    if not w or not w.address then return end

    -- Float cửa sổ
    hl.dispatch(hl.dsp.window.float({ action = "on", window = w }))

    -- Kích thước 97% width, 93% height (chừa mép thẩm mỹ và dock)
    local sz = fn.resize_by_screen(97, 93)
    if sz then
        sz.window = w
        hl.dispatch(hl.dsp.window.resize(sz))
    end

    -- Căn giữa màn hình và đưa lên lớp trên cùng (Top Z-order stack)
    hl.dispatch(hl.dsp.window.center({ window = w }))
    hl.dispatch(hl.dsp.window.alter_zorder({ mode = "top", window = w }))
end

-- 5. Xử lý sự kiện cửa sổ
local function handle_dock_window(w)
    if not w or not w.address then return end
    if handled_windows[w.address] then return end

    -- Bỏ qua các cửa sổ của hệ thống shell và screen picker
    local cls = w.class or ""
    if cls == "hyprpicker" or cls == "caelestia" then return end

    -- Bỏ qua nếu là hộp thoại nhỏ (file picker, save dialog, properties)
    local title = w.title or ""
    if title:find("Select", 1, true) or
       title:find("Open", 1, true) or
       title:find("Save As", 1, true) or
       title:find("Properties", 1, true) then
        return
    end

    local is_dock = false

    -- Phương pháp 1: /proc PID và PPID
    if w.pid and is_dock_proc(w.pid) then
        is_dock = true
    end

    -- Phương pháp 2: Tín hiệu Dock gần nhất
    if not is_dock then
        local sig = get_dock_launch_signal()
        if sig then
            local init_cls = w.initialClass or ""
            if matches_dock_cmd(sig.cmd, cls, init_cls, title) then
                is_dock = true
                consume_dock_signal()
            end
        end
    end

    if is_dock then
        handled_windows[w.address] = true

        -- Bước 1: Áp dụng ngay lập tức
        apply_dock_layout(w)

        -- Bước 2: Bồi thêm ở 100ms để khóa layout không bị dwindle kéo lại
        hl.timer(function()
            apply_dock_layout(w)
        end, { timeout = 100, type = "oneshot" })

        -- Bước 3: Bồi thêm ở 350ms cho các app khởi động nặng (Docker, Electron, IDE)
        hl.timer(function()
            apply_dock_layout(w)
        end, { timeout = 350, type = "oneshot" })
    end
end

-- Lắng nghe cả 3 sự kiện để bắt trọn mọi giai đoạn xuất hiện của cửa sổ
hl.on("window.open", handle_dock_window)
hl.on("window.class", handle_dock_window)
hl.on("window.title", handle_dock_window)

return {
    is_dock_proc = is_dock_proc,
    get_dock_launch_signal = get_dock_launch_signal,
    matches_dock_cmd = matches_dock_cmd,
    apply_dock_layout = apply_dock_layout,
}
