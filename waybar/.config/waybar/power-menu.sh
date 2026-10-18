#!/usr/bin/env bash

chosen=$(printf '%s\n' \
    '  Lock' \
    '󰍃  Logout' \
    '󰜉  Reboot' \
    '  Shutdown' |
    wofi --dmenu \
         --prompt "Power" \
         --width 220 \
         --height 220 \
         --cache-file /dev/null)

case "$chosen" in
    *Lock*) loginctl lock-session ;;
    *Logout*) hyprctl dispatch exit ;;
    *Reboot*) systemctl reboot ;;
    *Shutdown*) systemctl poweroff ;;
esac