#!/bin/bash
# Blank the Huawei MateBook E EC backlight when the lid closes; restore on open.
BL=/sys/class/backlight/planck-ec-backlight
SAVE=/run/planck-lid-brightness

find_ev() {
    for e in /sys/class/input/event*/device/name; do
        n=$(cat "$e" 2>/dev/null)
        if [ "$n" = "planck-ec" ]; then
            d=$(dirname "$(dirname "$e")")     # .../eventN
            echo "/dev/input/$(basename "$d")"
            return 0
        fi
    done
    return 1
}

# Wait for the backlight and lid device (up to ~60s)
EV=""
for i in $(seq 1 60); do
    [ -e "$BL/brightness" ] || { sleep 1; continue; }
    EV=$(find_ev) && break
    sleep 1
done
[ -e "$BL/brightness" ] || exit 1
[ -n "$EV" ] && [ -e "$EV" ] || exit 1

exec stdbuf -oL evtest "$EV" 2>/dev/null | while IFS= read -r l; do
    case "$l" in
        *"code 0 (SW_LID), value 1"*)
            # lid closed -> save brightness and turn the backlight off
            cat "$BL/brightness" > "$SAVE" 2>/dev/null
            echo 0 > "$BL/brightness"
            ;;
        *"code 0 (SW_LID), value 0"*)
            # lid opened -> restore brightness
            if [ -f "$SAVE" ]; then
                v=$(cat "$SAVE" 2>/dev/null)
                case "$v" in ''|*[!0-9]*) v=93 ;; esac
                [ "$v" -gt 0 ] 2>/dev/null || v=93
                echo "$v" > "$BL/brightness"
                rm -f "$SAVE"
            fi
            ;;
    esac
done
