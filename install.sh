#!/usr/bin/env bash
set -euo pipefail

DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
PACKAGES=(hypr waybar rofi wofi eww gtk thunar fastfetch cava wallpapers)
PKG_FILES=("$DOTS/packages/pacman.txt" "$DOTS/packages/aur.txt")

INSTALL_DEPS=ask
ASSUME_YES=0

usage() {
  cat <<EOF
Usage: ./install.sh [options]

  --deps        Install dependencies without asking
  --no-deps     Skip dependency installation
  -y, --yes     Answer yes to all prompts
  -h, --help    Show this help
EOF
}

for arg in "$@"; do
  case "$arg" in
    --deps)     INSTALL_DEPS=yes ;;
    --no-deps)  INSTALL_DEPS=no ;;
    -y|--yes)   ASSUME_YES=1 ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "Unknown option: $arg"; usage; exit 1 ;;
  esac
done

info()  { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
error() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; }

confirm() {
  [[ $ASSUME_YES -eq 1 ]] && return 0
  local reply
  read -rp "$1 [Y/n] " reply
  [[ "${reply:-Y}" =~ ^[Yy]$ ]]
}

if [[ $EUID -eq 0 ]]; then
  error "Do not run this as root. It will ask for sudo when needed."
  exit 1
fi

find_aur_helper() {
  for h in yay paru; do
    command -v "$h" >/dev/null 2>&1 && { echo "$h"; return 0; }
  done
  return 1
}

bootstrap_yay() {
  info "Installing yay from the AUR"
  sudo pacman -S --needed --noconfirm base-devel git
  local tmp
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
}

read_pkg_lists() {
  local f
  for f in "${PKG_FILES[@]}"; do
    [[ -s "$f" ]] && grep -vE '^\s*(#|$)' "$f" | awk '{print $1}'
  done | sort -u
}

install_deps() {
  if ! command -v pacman >/dev/null 2>&1; then
    warn "pacman not found. Skipping dependency install."
    warn "Install the tools listed in packages/*.txt manually."
    return
  fi

  sudo pacman -Sy --needed --noconfirm git stow base-devel

  local helper=""
  if ! helper="$(find_aur_helper)"; then
    if confirm "No AUR helper (yay/paru) found. Install yay now?"; then
      bootstrap_yay
      helper=yay
    else
      warn "Continuing without an AUR helper. AUR packages will be skipped."
    fi
  fi
  info "AUR helper: ${helper:-none}"

  mapfile -t wanted < <(read_pkg_lists)
  if [[ ${#wanted[@]} -eq 0 ]]; then
    warn "No package lists found in packages/. Skipping."
    return
  fi

  local repo_pkgs=() aur_pkgs=() p
  for p in "${wanted[@]}"; do
    if pacman -Si "$p" >/dev/null 2>&1; then
      repo_pkgs+=("$p")
    else
      aur_pkgs+=("$p")
    fi
  done

  if [[ ${#repo_pkgs[@]} -gt 0 ]]; then
    info "Installing ${#repo_pkgs[@]} packages from the official repos"
    sudo pacman -S --needed "${repo_pkgs[@]}"
  fi

  if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
    info "Not in official repos (will use the AUR): ${aur_pkgs[*]}"
    if [[ -z "$helper" ]]; then
      warn "Skipping AUR packages. Install these manually: ${aur_pkgs[*]}"
      return
    fi
    "$helper" -S --needed "${aur_pkgs[@]}"
  fi
}

case "$INSTALL_DEPS" in
  yes) install_deps ;;
  ask) confirm "Install dependencies?" && install_deps || true ;;
  no)  ;;
esac

if ! command -v stow >/dev/null 2>&1; then
  error "GNU Stow is required. Install it (sudo pacman -S stow) and rerun."
  exit 1
fi

info "Checking for existing configs that would conflict"
backed_up=0
for pkg in "${PACKAGES[@]}"; do
  [[ -d "$DOTS/$pkg" ]] || { warn "Package '$pkg' not found in repo, skipping"; continue; }
  while IFS= read -r -d '' f; do
    rel="${f#"$DOTS/$pkg/"}"
    target="$HOME/$rel"
    if [[ -e "$target" && ! -L "$target" && "$(readlink -f "$target")" != "$DOTS/"* ]]; then
      mkdir -p "$BACKUP/$(dirname "$rel")"
      mv "$target" "$BACKUP/$rel"
      info "Backed up $target"
      backed_up=1
    fi
  done < <(find "$DOTS/$pkg" -type f -print0)
done
[[ $backed_up -eq 0 ]] && rmdir "$BACKUP" 2>/dev/null || true

existing=()
for pkg in "${PACKAGES[@]}"; do
  [[ -d "$DOTS/$pkg" ]] && existing+=("$pkg")
done

info "Linking configs with stow"
cd "$DOTS"
stow -t "$HOME" --restow "${existing[@]}"

info "Making scripts executable"
find "$DOTS" -type f \( -name "*.sh" -o -path "*/scripts/*" \) \
  -not -path "$DOTS/.git/*" -exec chmod +x {} + 2>/dev/null || true

if [[ ! -e "$HOME/.config/gtk-3.0/bookmarks" ]]; then
  info "Generating GTK bookmarks"
  mkdir -p "$HOME/.config/gtk-3.0"
  for d in Documents Music Pictures Videos Downloads; do
    echo "file://$HOME/$d"
  done > "$HOME/.config/gtk-3.0/bookmarks"
fi

for d in Documents Music Pictures Videos Downloads; do
  mkdir -p "$HOME/$d"
done

if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f >/dev/null 2>&1 || true
fi

echo
info "Done."
[[ -d "$BACKUP" ]] && info "Your old configs were saved to $BACKUP"
echo "   Log out and pick Hyprland, or run: hyprctl reload"
