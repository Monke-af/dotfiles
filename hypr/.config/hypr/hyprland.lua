render = {
    direct_scanout = 0,
}
-- Monitor configuration
-- Fallback for any monitor: native resolution, auto position
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})




-- Monitor configuration
hl.monitor({
    output = "DP-3",
    mode = "1920x1080@165",
    position = "auto",
    scale = 1,
    vrr = 2,
})


-- Window settings: mouse-only border resizing
hl.config({
    general = {
        resize_on_border = true,
        extend_border_grab_area = 15,
        hover_icon_on_border = true,
    },

    animations = {
        enabled = true,
    },
    misc = { focus_on_activate = true }
})

-- Smooth animations
hl.curve("smoothOut", {
    type = "bezier",
    points = {
        {0.22, 1},
        {0.36, 1},
    },
})

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4,
    bezier = "smoothOut",
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 4,
    bezier = "smoothOut",
    style = "popin 85%",
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 3,
    bezier = "smoothOut",
    style = "popin 85%",
})

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 4,
    bezier = "smoothOut",
    style = "fade",
})


-- Switch workspaces with Super + 1–5
-- Move windows with Super + Shift + 1–5
for i = 1, 5 do
    hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

--Rofi Emoji Selector
hl.bind("ALT + PERIOD", hl.dsp.exec_cmd("rofimoji --action copy"))

-- Application keybindings
hl.bind("SUPER + B", hl.dsp.exec_cmd("firefox"))
hl.bind("SUPER + F", hl.dsp.exec_cmd("thunar"))
hl.bind("SUPER + T", hl.dsp.exec_cmd("alacritty"))

-- Select a region and copy screenshot ONLY to clipboard
hl.bind(
    "SUPER + SHIFT + S",
    hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]])
)

-- Close active window
hl.bind("SUPER + Q", hl.dsp.window.close())

-- Switch to previous window
hl.bind("ALT + TAB", hl.dsp.focus({ workspace = "previous" }))

-- Win + R: Open Rofi application launcher
hl.bind("SUPER + R", hl.dsp.exec_cmd("rofi -show drun"))

-- Volume management
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))


-- Wallpaper startup
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sh -c 'sleep 1; awww img --transition-type fade --transition-duration 2 \"$HOME/.local/share/wallpapers/3609962.jpg\"'")
    hl.exec_cmd("eww daemon")
    hl.exec_cmd("sh -c 'sleep 3; eww open visualizer'")
    hl.exec_cmd("~/.config/eww/empty-ws.sh")
    hl.exec_cmd("steam -silent")
    hl.exec_cmd("discord --start-minimized")
    hl.exec_cmd("gsr-ui")
    hl.exec_cmd("easyeffects --gapplication-service")
    hl.exec_cmd("~/.config/waybar/bluetooth-agent.py")

end)

-- Mouse acceleration
hl.config({
    input = {
        accel_profile = "flat",
    },
})
