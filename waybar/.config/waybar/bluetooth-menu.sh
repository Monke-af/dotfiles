#!/usr/bin/env bash

pkill -x wofi && exit 0

DIR="$HOME/.config/waybar/scripts"
RECV_DIR="$HOME/Downloads/Bluetooth"
WOFI=(wofi --dmenu --location 3 --xoffset -12 --yoffset 48 --width 320 --cache-file /dev/null --insensitive)

notify() { notify-send -t 2500 "Bluetooth" "$1" 2>/dev/null; }
powered() { bluetoothctl show | grep -q "Powered: yes"; }
is_connected() { bluetoothctl info "$1" | grep -q "Connected: yes"; }
is_trusted() { bluetoothctl info "$1" | grep -q "Trusted: yes"; }
confirm() { [ "$(printf 'Yes\nNo\n' | "${WOFI[@]}" --prompt "$1")" = "Yes" ]; }

ensure_agent() {
    pgrep -f "bluetooth-agent.py" >/dev/null || setsid "$DIR/bluetooth-agent.py" >/dev/null 2>&1 &
    sleep 0.4
}

paired_devices() {
    bluetoothctl devices Paired 2>/dev/null || bluetoothctl paired-devices
}

unpaired_devices() {
    local paired
    paired=$(paired_devices | awk '{print $2}')
    bluetoothctl devices | while read -r _ mac name; do
        [[ "$name" =~ ^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$ ]] && continue
        grep -q "$mac" <<< "$paired" || echo "Device $mac $name"
    done
}

pick_device() {
    local prompt="$1" source="$2" mac name choice
    declare -A map
    local entries=""
    while read -r _ mac name; do
        [ -z "$mac" ] && continue
        map["$name"]="$mac"
        entries+="$name"$'\n'
    done < <($source)
    [ -z "$entries" ] && { notify "No devices found"; return 1; }
    choice=$(printf '%s' "$entries" | "${WOFI[@]}" --prompt "$prompt") || return 1
    echo "${map[$choice]}"
}

pair_new() {
    local mac
    ensure_agent
    notify "Scanning for 8 seconds..."
    bluetoothctl --timeout 8 scan on >/dev/null 2>&1
    mac=$(pick_device "Pair" unpaired_devices) || return
    notify "Pairing... confirm any prompt that appears"
    if timeout 60 bluetoothctl pair "$mac" >/dev/null 2>&1; then
        bluetoothctl trust "$mac" >/dev/null
        bluetoothctl connect "$mac" >/dev/null 2>&1
        notify "Paired and connected"
    else
        notify "Pairing failed"
    fi
}

receive_mode() {
    local secs=120 name
    name=$(bluetoothctl show | awk -F': ' '/Alias:/ {print $2; exit}')
    mkdir -p "$RECV_DIR"
    ensure_agent

    bluetoothctl discoverable-timeout "$secs" >/dev/null
    bluetoothctl pairable on >/dev/null
    bluetoothctl discoverable on >/dev/null
    notify "Visible as \"$name\" for ${secs}s. Pair or send files from your phone."

    setsid bash -c '
        pkill -x obexd 2>/dev/null
        /usr/lib/bluetooth/obexd -n -a -r "$2" >/dev/null 2>&1 &
        sleep "$1"
        pkill -x obexd
        bluetoothctl discoverable off >/dev/null
        notify-send -t 2500 "Bluetooth" "Receive mode ended"
    ' _ "$secs" "$RECV_DIR" >/dev/null 2>&1 &
}

device_menu() {
    local mac="$1" name="$2" conn trust opts choice
    if is_connected "$mac"; then conn="󰂲  Disconnect"; else conn="󰂱  Connect"; fi
    if is_trusted "$mac"; then trust="󰌿  Untrust"; else trust="󰌾  Trust"; fi

    opts="$conn
$trust
󰒊  Send file
󰆴  Remove device
󰁍  Back"

    choice=$(printf '%s\n' "$opts" | "${WOFI[@]}" --prompt "$name") || exit 0

    case "$choice" in
        *"Disconnect")
            bluetoothctl disconnect "$mac" >/dev/null && notify "Disconnected from $name"
            exit 0
            ;;
        *"Connect")
            notify "Connecting to $name..."
            bluetoothctl connect "$mac" >/dev/null 2>&1 && notify "Connected to $name" || notify "Connection failed"
            exit 0
            ;;
        *"Untrust")
            bluetoothctl untrust "$mac" >/dev/null && notify "$name is no longer trusted"
            exit 0
            ;;
        *"Trust")
            bluetoothctl trust "$mac" >/dev/null && notify "$name is trusted"
            exit 0
            ;;
        *"Send file")
            blueman-sendto --device="$mac"
            exit 0
            ;;
        *"Remove device")
            confirm "Remove $name?" && bluetoothctl remove "$mac" >/dev/null && notify "$name removed"
            exit 0
            ;;
        *"Back")
            return
            ;;
    esac
}

if ! powered; then
    choice=$(printf '%s\n' "󰂯  Turn on" | "${WOFI[@]}" --prompt "Bluetooth")
    [ "$choice" = "󰂯  Turn on" ] && bluetoothctl power on >/dev/null && notify "Bluetooth on"
    exit 0
fi

ensure_agent

while true; do
    unset DEV
    declare -A DEV
    entries=""
    while read -r _ mac name; do
        [ -z "$mac" ] && continue
        if is_connected "$mac"; then label="󰂱  $name"; else label="󰂯  $name"; fi
        DEV["$label"]="$mac|$name"
        entries+="$label"$'\n'
    done < <(paired_devices)

    entries+="󰐕  Pair new device
󰂳  Receive / Be discoverable
󰉋  Open received files
󰂲  Turn off"

    choice=$(printf '%s\n' "$entries" | "${WOFI[@]}" --prompt "Bluetooth") || exit 0

    case "$choice" in
        *"Pair new device")
            pair_new
            exit 0
            ;;
        *"Receive / Be discoverable")
            receive_mode
            exit 0
            ;;
        *"Open received files")
            mkdir -p "$RECV_DIR"
            thunar "$RECV_DIR" &
            exit 0
            ;;
        *"Turn off")
            bluetoothctl power off >/dev/null && notify "Bluetooth off"
            exit 0
            ;;
        *)
            if [ -n "${DEV[$choice]}" ]; then
                IFS='|' read -r mac name <<< "${DEV[$choice]}"
                device_menu "$mac" "$name"
            fi
            ;;
    esac
done
