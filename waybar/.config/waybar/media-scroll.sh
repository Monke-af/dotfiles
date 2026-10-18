#!/usr/bin/env bash
export LC_ALL=C.UTF-8

WIDTH=28
SEP="   •   "
INTERVAL=0.25

play_icon=$(printf '\uf04b')
pause_icon=$(printf '\uf04c')

esc() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  printf '%s' "$s"
}

offset=0
tick=0
last=""
status=""
full=""

while true; do
  if (( tick % 2 == 0 )); then
    status=$(playerctl status 2>/dev/null)
    if [[ "$status" == "Playing" || "$status" == "Paused" ]]; then
      artist=$(playerctl metadata artist 2>/dev/null)
      title=$(playerctl metadata title 2>/dev/null)
      if [[ -n "$artist" ]]; then
        full="$artist - $title"
      else
        full="$title"
      fi
    else
      full=""
    fi
  fi
  tick=$((tick + 1))

  if [[ -z "$full" ]]; then
    echo '{"text":"","class":"stopped"}'
    last=""
    offset=0
    sleep "$INTERVAL"
    continue
  fi

  if [[ "$full" != "$last" ]]; then
    last="$full"
    offset=0
  fi

  if [[ "$status" == "Playing" ]]; then
    icon=$play_icon
  else
    icon=$pause_icon
  fi

  if (( ${#full} > WIDTH )); then
    padded="$full$SEP"
    len=${#padded}
    doubled="$padded$padded"
    view=${doubled:offset:WIDTH}
    if [[ "$status" == "Playing" ]]; then
      offset=$(( (offset + 1) % len ))
    fi
  else
    view=$full
  fi

  printf '{"text":"%s  %s","tooltip":"%s","class":"%s"}\n' \
    "$icon" "$(esc "$view")" "$(esc "$full")" "${status,,}"

  sleep "$INTERVAL"
done
