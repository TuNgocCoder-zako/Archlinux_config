#!/usr/bin/env bash
PNG_PATH="/tmp/caelestia-search.png"
DONE_FILE="/tmp/caelestia-search.done"
JPG_PATH="/tmp/orion_snippet.jpg"

rm -f "$PNG_PATH" "$DONE_FILE" "$JPG_PATH"

# Trigger Caelestia's native interactive Area Picker UI
qs -c caelestia ipc call picker openSearch

# Wait up to 60s for user to select a box or cancel
for ((i=1; i<=600; i++)); do
    if [ -f "$DONE_FILE" ] && [ -f "$PNG_PATH" ]; then
        break
    fi
    # Check if picker window closed without creating done file (user pressed Esc)
    if [ $i -gt 8 ]; then
        if ! hyprctl layers -j 2>/dev/null | grep -q '"caelestia-area-picker"'; then
            if [ ! -f "$DONE_FILE" ]; then
                echo "CANCELLED"
                exit 1
            fi
        fi
    fi
    sleep 0.1
done

if [ ! -f "$PNG_PATH" ]; then
    echo "CANCELLED"
    exit 1
fi

rm -f "$DONE_FILE"

# Optimize with Magick for AI vision (resize if larger than 1600x1600)
magick "$PNG_PATH" -resize '1600x1600>' -quality 92 "$JPG_PATH" >/dev/null 2>&1
if [ -f "$JPG_PATH" ]; then
    TARGET="$JPG_PATH"
else
    TARGET="$PNG_PATH"
fi

echo "$TARGET"
