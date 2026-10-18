#!/usr/bin/env bash

sock="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
state=""

until eww ping >/dev/null 2>&1; do
  sleep 0.5
done

update() {
  n=$(hyprctl activeworkspace -j | jq '.windows')
  if [ "$n" = "0" ]; then
    new="open"
  else
    new="closed"
  fi

  if [ "$new" != "$state" ]; then
    state="$new"
    if [ "$new" = "open" ]; then
      eww open fetch 2>/dev/null
    else
      eww close fetch 2>/dev/null
    fi
  fi
}

update

socat -u UNIX-CONNECT:"$sock" - | while read -r line; do
  case "$line" in
    openwindow*|closewindow*|movewindow*|workspace*|focusedmon*|createworkspace*|destroyworkspace*|fullscreen*)
      sleep 0.05
      update
      ;;
  esac
done
