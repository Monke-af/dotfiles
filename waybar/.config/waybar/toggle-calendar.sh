#!/usr/bin/env bash

if eww active-windows | grep -q '^calendar_window:'; then
    eww close calendar_window
else
    eww open calendar_window
fi
