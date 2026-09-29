function fish_greeting
    set -l audio_path "/home/tu/Music/re-zero-return-by-death.wav"
    test -f "$audio_path"; or set audio_path "/home/tu/Music/re-zero-return-by-death.mp3"
    if test -f "$audio_path"
        if command -v pw-play &>/dev/null
            pw-play "$audio_path" >/dev/null 2>&1 &
            disown
        else if command -v paplay &>/dev/null
            paplay "$audio_path" >/dev/null 2>&1 &
            disown
        end
    end

    set_color -o cba6f7; echo '     ______           __          __  _       '
    set_color -o b4befe; echo '    / ____/___ ____  / /__  _____/ /_(_)___ _ '
    set_color -o 89dceb; echo '   / /   / __ `/ _ \/ / _ \/ ___/ __/ / __ `/ '
    set_color -o 94e2d5; echo '  / /___/ /_/ /  __/ /  __(__  ) /_/ / /_/ /  '
    set_color -o a6e3a1; echo '  \____/\__,_/\___/_/\___/____/\__/_/\__,_/   '
    set_color normal

    if command -v fastfetch &>/dev/null
        fastfetch --key-padding-left 5
    end
end
