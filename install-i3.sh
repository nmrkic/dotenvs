#!/usr/bin/env bash
# Podiže i3 desktop na Ubuntu/Debian računaru: instalira pakete, linkuje i3
# grupu dotfiles-a i podešava GDM sesiju. Odvojeno od install.sh jer i3 ne ide
# na svaki računar.
#
# Bezbedno za ponovno pokretanje: već instalirani paketi i ispravni fajlovi se
# preskaču, pa sudo traži samo kad stvarno ima šta da uradi.
#
#   ./install-i3.sh       instaliraj i podesi
#   ./install-i3.sh -n    samo ispiši šta bi uradio
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
        echo "ok      svi paketi su već instalirani"
        return
    fi
    echo "install ${missing[*]}"
    run sudo apt-get install -y "${missing[@]}"
}

for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY_RUN=1 ;;
        -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Nepoznat argument: $arg" >&2; exit 1 ;;
    esac
done

if ! command -v apt-get >/dev/null 2>&1; then
    echo "Ova skripta radi samo na sistemima sa apt-om (Ubuntu/Debian)." >&2
    exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then echo "(dry run, ništa se ne menja)"; fi

echo "== paketi"
apt_install "${PACKAGES[@]}"

if [ "$DRY_RUN" -eq 1 ]; then
    "$REPO/install.sh" -n i3 | sed -e '1d' -e '/^$/,$d'
else
    "$REPO/install.sh" i3 | sed '/^$/,$d'
fi

# Binarni fajl je u repou, ali je kompajliran za x86-64; na drugoj arhitekturi
# ili bez libX11 ne može da se pokrene, pa ga tada kompajliramo iz izvora.
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

# GDM čita samo /usr/share/xsessions, a i3 paket pri update-u vraća original,
# pa se Exec ovde upućuje na i3-x11 wrapper ovog korisnika.
echo "== GDM sesija"
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

Gotovo. Odjavi se i na GDM ekranu izaberi sesiju "i3".
Ručno ostaje (vidi README.md):
  - snixembed (tray za polybar) se ne instalira preko apt-a
  - pozadina: i3 config očekuje ~/Pictures/dark-blue.jpg
  - Chrome wrapper sa GPU flagovima, samo ako Chrome pravi probleme (sekcija 4)
  - monitor layout za ovaj računar preko arandr-a (sekcija 5)
EOF
