#!/usr/bin/env bash

BARS=24
CONF=/tmp/eww-cava.conf

pkill -f "cava -p $CONF" 2>/dev/null

cat > "$CONF" <<EOF
[general]
bars = $BARS
framerate = 30

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
frame_delimiter = 10
EOF

cava -p "$CONF" | sed -u 's/;$//; s/^/[/; s/;/,/g; s/$/]/'
