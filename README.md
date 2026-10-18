# dotfiles

A minimal, monochrome Hyprland desktop for Arch Linux: near-black, high contrast, no accent colors, one font everywhere.

<!-- Add screenshots to a `screenshots/` folder and uncomment: -->
<!-- ![Desktop](screenshots/desktop.png) -->
<!-- ![Rofi and Waybar](screenshots/launcher.png) -->

## What's included

| Component | Purpose |
|-----------|---------|
| **Hyprland** | Window manager (configured in `hyprland.lua`) |
| **Waybar** | Transparent bar with pill-style modules, scrolling media track, audio and power menus |
| **Rofi / Wofi** | Launcher, power menu and audio-device menu |
| **eww** | Desktop widgets: fastfetch info panel and cava audio visualizer |
| **cava** | Audio visualizer config and shaders |
| **fastfetch** | System info config |
| **GTK / Thunar** | Matching theme for GTK apps and the Thunar file manager |
| **awww** | Wallpaper daemon with a fade transition |

**Theme**

| Role | Color |
|------|-------|
| Background | `#080808` |
| Secondary background | `#101010` |
| Borders | `#242424` |
| Hover | `#303030` |
| Text | `#F5F5F5` |
| Inactive / muted | `#999999` / `#AAAAAA` |

Font: JetBrainsMono Nerd Font.

## Requirements

- An Arch-based system (the installer uses `pacman`)
- A Hyprland version that supports Lua configuration, since the config is `hyprland.lua`
- A working internet connection for package installation

## Install

```bash
git clone https://github.com/Monke-af/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer will:
1. Install dependencies from `packages/pacman.txt` and `packages/aur.txt`, sorting each package into the official repos or the AUR automatically, and offer to install `yay` if you have no AUR helper.
2. Move any existing configs that would conflict into `~/.dotfiles-backup/<timestamp>/`.
3. Symlink everything into place with [GNU Stow](https://www.gnu.org/software/stow/).
4. Make the scripts executable and generate GTK bookmarks for your home folders.

Options:

```
./install.sh --deps      install dependencies without asking
./install.sh --no-deps   skip dependency installation
./install.sh -y          answer yes to every prompt
```

Log out and pick **Hyprland** from your display manager, or run `hyprctl reload` if you're already in a session.

### Manual install

```bash
sudo pacman -S git stow
git clone https://github.com/Monke-af/dotfiles.git ~/dotfiles
cd ~/dotfiles
# install the packages listed in packages/pacman.txt and packages/aur.txt, then:
stow -t ~ hypr waybar rofi wofi eww gtk thunar fastfetch cava wallpapers alacritty
```

Back up your existing `~/.config/<app>` folders first. Stow refuses to overwrite real files.

## Customizing

- **Monitor**: edit the `hl.monitor` blocks at the top of `hypr/.config/hypr/hyprland.lua`. The first is a generic fallback, the second is for the author's display; change or remove it.
- **Wallpaper**: replace `wallpapers/.local/share/wallpapers/3609962.jpg` and update the path in `hyprland.lua`.
- **Colors**: the palette is repeated in the Waybar, Rofi, Wofi, eww and GTK stylesheets. Change them together to keep everything consistent.
- **Keybinds**: see the bindings section of `hyprland.lua`.

## Layout

```
dotfiles/
├── install.sh
├── packages/        # pacman.txt, aur.txt
├── hypr/            # each folder is a Stow package that mirrors $HOME
├── waybar/
├── rofi/
├── wofi/
├── eww/
├── gtk/
├── thunar/
├── fastfetch/
├── cava/
└── wallpapers/
```

To remove a package's symlinks: `stow -t ~ -D <package>`.

## Credits

<!-- List the sources of anything you didn't make yourself: icon pack, GTK theme, wallpaper, borrowed scripts, shaders. -->
- Wallpaper: _add source and licence_
- Icon theme: _add name and link_
- cava shaders: from the [cava](https://github.com/karlstav/cava) project

## License

[MIT](LICENSE)
