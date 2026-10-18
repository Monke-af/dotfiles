#!/usr/bin/env bash
export LC_ALL=C.UTF-8
/usr/bin/fastfetch --pipe 2>/dev/null | sed 's/\\/\\\\/g'
