#!/usr/bin/env python3
"""
🌸 Anime Control Center for Hyprland (Catppuccin Mocha Theme)
Features:
- Live Media Player (Album Art, Song Title, Artist, Play/Pause/Prev/Next)
- Quick Toggles (Wi-Fi, Bluetooth, Night Light, Power Saver, DND, Mute Mic)
- Sliders (Volume, Brightness)
- System status & notification shortcuts
"""

import os
import sys
import subprocess
import gi

gi.require_version("Gtk", "3.0")
try:
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import GtkLayerShell
    HAS_LAYER_SHELL = True
except (ValueError, ImportError):
    HAS_LAYER_SHELL = False

from gi.repository import Gtk, Gdk, GLib, GdkPixbuf, Pango

# ── Helper Commands ──
def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, shell=True, text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return ""

def exec_cmd(cmd):
    subprocess.Popen(cmd, shell=True)

class AnimeControlCenter(Gtk.Window):
    def __init__(self):
        super().__init__(title="Anime Control Center")
        self.set_default_size(360, 520)
        self.set_resizable(False)
        self.set_name("control-center-window")

        if HAS_LAYER_SHELL:
            GtkLayerShell.init_for_window(self)
            GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
            GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
            GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 48)
            GtkLayerShell.set_margin(self, GtkLayerShell.Edge.RIGHT, 14)
            GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)
        else:
            self.set_position(Gtk.WindowPosition.MOUSE)
            self.set_type_hint(Gdk.WindowTypeHint.DIALOG)

        # Connect key press for ESC to close
        self.connect("key-press-event", self.on_key_press)
        self.connect("focus-out-event", lambda w, e: self.close_app())

        # Main Layout Box
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=14)
        main_box.set_name("main-container")
        self.add(main_box)

        # 1. Header (User + Battery + Power button)
        main_box.pack_start(self.create_header(), False, False, 0)

        # 2. Media Player Widget
        main_box.pack_start(self.create_media_player(), False, False, 0)

        # 3. Quick Toggles Grid (WiFi, BT, Night Light, etc.)
        main_box.pack_start(self.create_toggles(), False, False, 0)

        # 4. Sliders (Brightness & Volume)
        main_box.pack_start(self.create_sliders(), False, False, 0)

        # 5. Footer (Settings / Clear Notifs)
        main_box.pack_start(self.create_footer(), False, False, 0)

        # Periodic updates (every 2 seconds)
        GLib.timeout_add_seconds(2, self.update_status)

        self.load_css()
        self.update_status()

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_app()
            return True
        return False

    def close_app(self):
        Gtk.main_quit()
        sys.exit(0)

    # ── Header ──
    def create_header(self):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        box.set_name("header-box")

        user_lbl = Gtk.Label(label=f"🌸  {os.getenv('USER', 'User').capitalize()}'s Sanctuary")
        user_lbl.set_name("header-user")
        box.pack_start(user_lbl, True, True, 0)

        # Close button
        btn_close = Gtk.Button(label="✕")
        btn_close.set_name("btn-close")
        btn_close.connect("clicked", lambda b: self.close_app())
        box.pack_end(btn_close, False, False, 0)

        return box

    # ── Media Player ──
    def create_media_player(self):
        frame = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        frame.set_name("media-card")

        # Top row: Album cover + Info
        top_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)

        # Album Art Image
        self.album_art = Gtk.Image()
        self.album_art.set_name("media-art")
        self.album_art.set_size_request(64, 64)
        self.set_default_art()
        top_row.pack_start(self.album_art, False, False, 0)

        # Song Title & Artist Box
        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=3)
        info_box.set_valign(Gtk.Align.CENTER)

        self.lbl_title = Gtk.Label(label="Không có nhạc đang phát")
        self.lbl_title.set_name("media-title")
        self.lbl_title.set_xalign(0)
        self.lbl_title.set_ellipsize(Pango.EllipsizeMode.END)
        self.lbl_title.set_max_width_chars(20)

        self.lbl_artist = Gtk.Label(label="Mở Spotify hoặc trình duyệt 🎵")
        self.lbl_artist.set_name("media-artist")
        self.lbl_artist.set_xalign(0)
        self.lbl_artist.set_ellipsize(Pango.EllipsizeMode.END)
        self.lbl_artist.set_max_width_chars(20)

        info_box.pack_start(self.lbl_title, False, False, 0)
        info_box.pack_start(self.lbl_artist, False, False, 0)
        top_row.pack_start(info_box, True, True, 0)

        frame.pack_start(top_row, False, False, 0)

        # Controls Row (Prev, Play/Pause, Next)
        ctrl_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        ctrl_row.set_halign(Gtk.Align.CENTER)

        btn_prev = Gtk.Button(label="󰒮")
        btn_prev.set_name("media-btn")
        btn_prev.connect("clicked", lambda b: exec_cmd("playerctl previous"))

        self.btn_play = Gtk.Button(label="󰐊")
        self.btn_play.set_name("media-btn-play")
        self.btn_play.connect("clicked", lambda b: exec_cmd("playerctl play-pause"))

        btn_next = Gtk.Button(label="󰒭")
        btn_next.set_name("media-btn")
        btn_next.connect("clicked", lambda b: exec_cmd("playerctl next"))

        ctrl_row.pack_start(btn_prev, False, False, 0)
        ctrl_row.pack_start(self.btn_play, False, False, 0)
        ctrl_row.pack_start(btn_next, False, False, 0)

        frame.pack_start(ctrl_row, False, False, 0)
        return frame

    def set_default_art(self):
        self.album_art.set_from_icon_name("audio-x-generic", Gtk.IconSize.DIALOG)

    # ── Quick Toggles ──
    def create_toggles(self):
        grid = Gtk.Grid()
        grid.set_column_spacing(8)
        grid.set_row_spacing(8)
        grid.set_column_homogeneous(True)
        grid.set_name("toggles-grid")

        # 1. Wi-Fi
        self.btn_wifi = Gtk.Button(label="󰤨  Wi-Fi")
        self.btn_wifi.set_name("toggle-btn")
        self.btn_wifi.connect("clicked", self.toggle_wifi)
        grid.attach(self.btn_wifi, 0, 0, 1, 1)

        # 2. Bluetooth
        self.btn_bt = Gtk.Button(label="󰂯  Bluetooth")
        self.btn_bt.set_name("toggle-btn")
        self.btn_bt.connect("clicked", self.toggle_bluetooth)
        grid.attach(self.btn_bt, 1, 0, 1, 1)

        # 3. Night Light (gammastep/hyprshade)
        self.btn_night = Gtk.Button(label="󰌌  Night Light")
        self.btn_night.set_name("toggle-btn")
        self.btn_night.connect("clicked", self.toggle_night_light)
        grid.attach(self.btn_night, 2, 0, 1, 1)

        # 4. Screenshot Quick
        btn_shot = Gtk.Button(label="📸  Screenshot")
        btn_shot.set_name("toggle-btn")
        btn_shot.connect("clicked", lambda b: (self.close_app(), exec_cmd("sleep 0.3 && grim -g \"$(slurp -d)\" - | wl-copy && notify-send '📸 Screenshot' 'Đã copy vào clipboard'")))
        grid.attach(btn_shot, 0, 1, 1, 1)

        # 5. DND (Do Not Disturb)
        self.btn_dnd = Gtk.Button(label="󰂛  DND")
        self.btn_dnd.set_name("toggle-btn")
        self.btn_dnd.connect("clicked", self.toggle_dnd)
        grid.attach(self.btn_dnd, 1, 1, 1, 1)

        # 6. Lock Screen
        btn_lock = Gtk.Button(label="🔒  Khóa máy")
        btn_lock.set_name("toggle-btn")
        btn_lock.connect("clicked", lambda b: (self.close_app(), exec_cmd("swaylock --color 1e1e2e --indicator --indicator-radius 80 --ring-color cba6f7 --key-hl-color f5c2e7 --text-color cdd6f4 --inside-color 1e1e2e --line-uses-inside")))
        grid.attach(btn_lock, 2, 1, 1, 1)

        return grid

    # ── Sliders (Brightness & Volume) ──
    def create_sliders(self):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        box.set_name("sliders-card")

        # 1. Brightness Slider
        b_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        b_icon = Gtk.Label(label="󰃟")
        b_icon.set_name("slider-icon")
        b_row.pack_start(b_icon, False, False, 0)

        self.scale_bright = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 5, 100, 5)
        self.scale_bright.set_name("custom-slider")
        self.scale_bright.set_value(float(run_cmd("brightnessctl -m | cut -d, -f4 | tr -d '%'") or 80))
        self.scale_bright.connect("value-changed", lambda s: exec_cmd(f"brightnessctl s {int(s.get_value())}%"))
        b_row.pack_start(self.scale_bright, True, True, 0)
        box.pack_start(b_row, False, False, 0)

        # 2. Volume Slider
        v_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        v_icon = Gtk.Label(label="󰕾")
        v_icon.set_name("slider-icon")
        v_row.pack_start(v_icon, False, False, 0)

        cur_vol = float(run_cmd("wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}'") or 50)
        self.scale_vol = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 5)
        self.scale_vol.set_name("custom-slider")
        self.scale_vol.set_value(cur_vol)
        self.scale_vol.connect("value-changed", lambda s: exec_cmd(f"wpctl set-volume @DEFAULT_AUDIO_SINK@ {int(s.get_value())}%"))
        v_row.pack_start(self.scale_vol, True, True, 0)
        box.pack_start(v_row, False, False, 0)

        return box

    # ── Footer ──
    def create_footer(self):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        box.set_name("footer-box")

        btn_wall = Gtk.Button(label="🖼️  Đổi hình nền")
        btn_wall.set_name("footer-btn")
        btn_wall.connect("clicked", lambda b: (self.close_app(), exec_cmd("waypaper")))
        box.pack_start(btn_wall, True, True, 0)

        btn_clear = Gtk.Button(label="🔔  Xóa thông báo")
        btn_clear.set_name("footer-btn")
        btn_clear.connect("clicked", lambda b: exec_cmd("makoctl dismiss -a"))
        box.pack_start(btn_clear, True, True, 0)

        return box

    # ── Logic Toggles ──
    def toggle_wifi(self, btn):
        state = run_cmd("nmcli radio wifi")
        if state == "enabled":
            exec_cmd("nmcli radio wifi off")
            self.set_btn_active(btn, False)
        else:
            exec_cmd("nmcli radio wifi on")
            self.set_btn_active(btn, True)

    def toggle_bluetooth(self, btn):
        state = run_cmd("bluetoothctl show | grep 'Powered: yes'")
        if state:
            exec_cmd("bluetoothctl power off")
            self.set_btn_active(btn, False)
        else:
            exec_cmd("bluetoothctl power on")
            self.set_btn_active(btn, True)

    def toggle_night_light(self, btn):
        if run_cmd("pgrep wlsunset"):
            exec_cmd("pkill wlsunset")
            self.set_btn_active(btn, False)
        else:
            exec_cmd("wlsunset -t 4500 &")
            self.set_btn_active(btn, True)

    def toggle_dnd(self, btn):
        mode = run_cmd("makoctl mode")
        if "dnd" in mode:
            exec_cmd("makoctl mode -r dnd")
            self.set_btn_active(btn, False)
        else:
            exec_cmd("makoctl mode -a dnd")
            self.set_btn_active(btn, True)

    def set_btn_active(self, btn, active):
        if active:
            btn.get_style_context().add_class("toggle-active")
        else:
            btn.get_style_context().remove_class("toggle-active")

    # ── Update Routine ──
    def update_status(self):
        # 1. Update Media
        status = run_cmd("playerctl status 2>/dev/null")
        if status in ["Playing", "Paused"]:
            title = run_cmd("playerctl metadata title 2>/dev/null") or "Không rõ tên"
            artist = run_cmd("playerctl metadata artist 2>/dev/null") or "Nghệ sĩ"
            self.lbl_title.set_text(title)
            self.lbl_artist.set_text(artist)
            self.btn_play.set_label("󰏤" if status == "Playing" else "󰐊")

            # Cover Art URL
            art_url = run_cmd("playerctl metadata mpris:artUrl 2>/dev/null")
            if art_url.startswith("file://"):
                path = art_url.replace("file://", "")
                if os.path.exists(path):
                    try:
                        pb = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, 64, 64, True)
                        self.album_art.set_from_pixbuf(pb)
                    except Exception:
                        self.set_default_art()
            else:
                self.set_default_art()
        else:
            self.lbl_title.set_text("Không có bài hát nào")
            self.lbl_artist.set_text("Mở Spotify / Youtube 🎵")
            self.btn_play.set_label("󰐊")
            self.set_default_art()

        # 2. Update Toggles state
        wifi = (run_cmd("nmcli radio wifi") == "enabled")
        self.set_btn_active(self.btn_wifi, wifi)

        bt = bool(run_cmd("bluetoothctl show | grep 'Powered: yes'"))
        self.set_btn_active(self.btn_bt, bt)

        night = bool(run_cmd("pgrep wlsunset"))
        self.set_btn_active(self.btn_night, night)

        dnd = ("dnd" in run_cmd("makoctl mode 2>/dev/null"))
        self.set_btn_active(self.btn_dnd, dnd)

        return True

    def load_css(self):
        try:
            css_provider = Gtk.CssProvider()
            css_file = os.path.expanduser("~/.config/hypr/control-center.css")
            if os.path.exists(css_file):
                css_provider.load_from_path(css_file)
                Gtk.StyleContext.add_provider_for_screen(
                    Gdk.Screen.get_default(),
                    css_provider,
                    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
                )
        except Exception as e:
            print(f"CSS Notice: {e}")

def main():
    # Toggle behavior: if already running, kill it and exit
    pid_file = "/tmp/anime_control_center.pid"
    if os.path.exists(pid_file):
        try:
            with open(pid_file, "r") as f:
                old_pid = int(f.read().strip())
            os.remove(pid_file)
            os.kill(old_pid, 9)
            sys.exit(0)
        except Exception:
            pass

    with open(pid_file, "w") as f:
        f.write(str(os.getpid()))

    win = AnimeControlCenter()
    win.show_all()
    Gtk.main()

if __name__ == "__main__":
    main()
