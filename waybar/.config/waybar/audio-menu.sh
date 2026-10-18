#!/usr/bin/env bash

default=$(pactl get-default-sink)

choice=$(pactl -f json list sinks \
  | jq -r --arg d "$default" '.[] | (if .name==$d then "● " else "○ " end) + .description' \
  | wofi --dmenu --location 3 --xoffset -12 --yoffset 48 \
         --width 340 --lines 5 --hide-search --hide-scroll --no-actions \
         --style "$HOME/.config/wofi/style.css" --cache-file /dev/null)

[ -z "$choice" ] && exit 0

desc="${choice:2}"
name=$(pactl -f json list sinks | jq -r --arg d "$desc" '.[] | select(.description==$d) | .name')

pactl set-default-sink "$name"

for id in $(pactl list short sink-inputs | cut -f1); do
  pactl move-sink-input "$id" "$name"
done
