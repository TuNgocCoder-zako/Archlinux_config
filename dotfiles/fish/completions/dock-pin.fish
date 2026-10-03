# Fish completion for dock-pin (macOS-style Dock Manager)

# Vô hiệu hóa gợi ý file/thư mục mặc định
complete -c dock-pin -f

# Lệnh con chính
complete -c dock-pin -n "__fish_use_subcommand" -a list -d "Xem danh sách ứng dụng đã ghim & trạng thái đa nhiệm"
complete -c dock-pin -n "__fish_use_subcommand" -a ls -d "Xem danh sách ứng dụng đã ghim"
complete -c dock-pin -n "__fish_use_subcommand" -a add -d "Ghim ứng dụng vào Dock"
complete -c dock-pin -n "__fish_use_subcommand" -a pin -d "Ghim ứng dụng vào Dock"
complete -c dock-pin -n "__fish_use_subcommand" -a remove -d "Bỏ ghim ứng dụng khỏi Dock"
complete -c dock-pin -n "__fish_use_subcommand" -a rm -d "Bỏ ghim ứng dụng khỏi Dock"
complete -c dock-pin -n "__fish_use_subcommand" -a unpin -d "Bỏ ghim ứng dụng khỏi Dock"
complete -c dock-pin -n "__fish_use_subcommand" -a toggle -d "Ẩn / Hiện thanh Dock ngay lập tức"
complete -c dock-pin -n "__fish_use_subcommand" -a show -d "Hiện thanh Dock"
complete -c dock-pin -n "__fish_use_subcommand" -a hide -d "Ẩn thanh Dock"
complete -c dock-pin -n "__fish_use_subcommand" -a reload -d "Khởi động lại service Dock"
complete -c dock-pin -n "__fish_use_subcommand" -a edit -d "Chỉnh sửa sắp xếp thứ tự icon"
complete -c dock-pin -n "__fish_use_subcommand" -a status -d "Xem trạng thái tiến trình Dock"

# Gợi ý danh sách app khi gõ dock-pin add <TAB>
complete -c dock-pin -n "__fish_seen_subcommand_from add pin -a" -a "(dock-pin complete apps)"

# Gợi ý danh sách app đã ghim khi gõ dock-pin remove <TAB>
complete -c dock-pin -n "__fish_seen_subcommand_from remove rm unpin -r" -a "(dock-pin complete pinned)"
