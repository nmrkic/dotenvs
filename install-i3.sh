#!/usr/bin/env bash
# Sets up the i3 desktop on an Ubuntu/Debian machine: installs packages, links
# the i3 group of dotfiles and configures the GDM session. Kept separate from
# install.sh because i3 doesn't go on every machine.
#
# Safe to re-run: packages that are already installed and files that are
# already correct are skipped, so sudo is only asked for when there is work.
#
#   ./install-i3.sh       install and configure
#   ./install-i3.sh -n    only print what it would do
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0

PACKAGES=(
    i3 i3lock rofi polybar dunst picom feh conky-all dex
    network-manager-gnome numlockx flameshot brightnessctl pulseaudio-utils
    arandr x11-xserver-utils x11-xkb-utils gnome-settings-daemon
)

run() {
    if [ "$DRY_RUN" -eq 0 ]; then "$@"; fi
}

installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q "install ok installed"
}

apt_install() {
    local missing=() pkg
    for pkg in "$@"; do
        if ! installed "$pkg"; then missing+=("$pkg"); fi
    done
    if [ "${#missing[@]}" -eq 0 ]; then
        echo "ok      all packages are already installed"
        return
    fi
    echo "install ${missing[*]}"
    run sudo apt-get install -y "${missing[@]}"
}

for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY_RUN=1 ;;
        -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown argument: $arg" >&2; exit 1 ;;
    esac
done

if ! command -v apt-get >/dev/null 2>&1; then
    echo "This script only works on systems with apt (Ubuntu/Debian)." >&2
    exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then echo "(dry run, nothing is changed)"; fi

echo "== packages"
apt_install "${PACKAGES[@]}"

if [ "$DRY_RUN" -eq 1 ]; then
    "$REPO/install.sh" -n i3 | sed -e '1d' -e '/^$/,$d'
else
    "$REPO/install.sh" i3 | sed '/^$/,$d'
fi

# The binary is in the repo, but it is built for x86-64; on another architecture
# or without libX11 it can't run, so then we build it from source.
echo "== layout-notify"
SCRIPTS="$REPO/.config/i3/scripts"
if ldd "$SCRIPTS/layout-notify" >/dev/null 2>&1 \
    && ! ldd "$SCRIPTS/layout-notify" | grep -q "not found"; then
    echo "ok      $SCRIPTS/layout-notify"
else
    apt_install gcc libx11-dev
    echo "gcc     $SCRIPTS/layout-notify"
    run gcc -o "$SCRIPTS/layout-notify" "$SCRIPTS/layout-notify.c" -lX11
fi

# GDM only reads /usr/share/xsessions, and the i3 package restores the original
# on update, so Exec here points to this user's i3-x11 wrapper.
echo "== GDM session"
XSESSION=/usr/share/xsessions/i3.desktop
WANTED="$(sed "s|^Exec=.*|Exec=$HOME/.local/bin/i3-x11|" "$REPO/system$XSESSION")"
if [ -f "$XSESSION" ] && [ "$(cat "$XSESSION")" = "$WANTED" ]; then
    echo "ok      $XSESSION"
else
    echo "install $XSESSION (Exec=$HOME/.local/bin/i3-x11)"
    if [ "$DRY_RUN" -eq 0 ]; then
        printf '%s\n' "$WANTED" | sudo tee "$XSESSION" >/dev/null
        sudo chmod 644 "$XSESSION"
    fi
fi

cat <<EOF

Done. Log out and pick the "i3" session on the GDM screen.
Left to do by hand (see README.md):
  - snixembed (tray for polybar) is not installed via apt
  - wallpaper: the i3 config expects ~/Pictures/dark-blue.jpg
  - Chrome wrapper with GPU flags, only if Chrome misbehaves (section 4)
  - monitor layout for this machine via arandr (section 5)
EOF
