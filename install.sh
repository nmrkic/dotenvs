#!/usr/bin/env bash
# Linkuje dotfiles iz ovog repoa u $HOME.
#
# Bezbedno za ponovno pokretanje: ispravni linkovi se preskaču, a ono što već
# postoji na ciljnoj lokaciji se sklanja u <ime>.bak-<datum> pre linkovanja.
#
#   ./install.sh              sve grupe za ovaj OS
#   ./install.sh zed claude   samo navedene grupe
#   ./install.sh -n [grupe]   samo ispiši šta bi uradio
#   ./install.sh --install-fish [grupe]
#                             pre linkovanja instalira fish ako ga nema, a posle
#                             ga postavi kao login shell (traži sudo/lozinku)
#
# Grupe: base tmux fish i3 zed claude claude-work
# Podrazumevano se linkuju base (u njoj je i tmux), fish, zed i claude. Grupa
# i3 se linkuje samo kad se izričito navede; ceo i3 desktop (paketi + linkovi
# + GDM) podiže ./install-i3.sh, a Mac (brew + fish, tmux, zed) ./install-mac.sh.
# claude-work linkuje isti Claude config u ~/.claude-work (poslovni nalog,
# CLAUDE_CONFIG_DIR) i takođe ide samo kad se navede.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0

run() {
    if [ "$DRY_RUN" -eq 0 ]; then "$@"; fi
}

# link <putanja u repou> [putanja u $HOME, ako se razlikuje]
link() {
    local src="$REPO/$1" dst="$HOME/${2:-$1}"
    if [ ! -e "$src" ]; then
        echo "FALI    $src"
        return
    fi
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "ok      $dst"
        return
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        echo "backup  $dst -> $dst.bak-$STAMP"
        run mv "$dst" "$dst.bak-$STAMP"
    fi
    echo "link    $dst"
    run mkdir -p "$(dirname "$dst")"
    run ln -s "$src" "$dst"
}

group_base() {
    link .vimrc
    link .tmate.conf
    link .gitconfig
    group_tmux
}

group_tmux() {
    link .tmux.conf
}

group_fish() {
    if [ "$(uname -s)" = "Darwin" ]; then
        # conf.d i fish_variables su vezani za Linux računar (virtualfish,
        # rustup, univerzalne promenljive), pa se na Mac-u linkuje fajl po fajl
        link .config/fish/config.fish
        link .config/fish/functions
        link .config/fish/fish_plugins
    else
        # ceo direktorijum, fish sam piše fish_variables/completions unutra
        link .config/fish
    fi
}

group_i3() {
    link .Xresources
    link .conkyrc
    link .conky
    link .config/i3/config
    link .config/i3/scripts
    link .config/rofi/config.rasi
    link .config/picom/picom.conf
    link .config/polybar/config.ini
    link .config/polybar/launch.sh
    link .config/polybar/scripts
    link .config/dunst/dunstrc
    link .screenlayout
    link .local/bin/i3-x11
    link .local/share/xsessions/i3.desktop
}

group_zed() {
    link .config/zed/settings.json
    link .config/zed/keymap.json
}

group_claude() {
    link .claude/settings.json
    link .claude/commands
    link .claude/skills
}

group_claude_work() {
    link .claude/settings.json .claude-work/settings.json
    link .claude/commands      .claude-work/commands
    link .claude/skills        .claude-work/skills
}

install_fish() {
    echo "== instalacija fish-a"
    if command -v fish >/dev/null 2>&1; then
        echo "ok      fish je već instaliran ($(command -v fish))"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "install fish (apt)"
        run sudo apt-get install -y fish
    elif command -v dnf >/dev/null 2>&1; then
        echo "install fish (dnf)"
        run sudo dnf install -y fish
    elif command -v pacman >/dev/null 2>&1; then
        echo "install fish (pacman)"
        run sudo pacman -S --noconfirm fish
    elif command -v brew >/dev/null 2>&1; then
        echo "install fish (brew)"
        run brew install fish
    else
        echo "Nema apt/dnf/pacman/brew, instaliraj fish ručno pa pokreni ponovo." >&2
        exit 1
    fi
}

default_shell_fish() {
    echo "== fish kao login shell"
    local fish_bin login_shell
    fish_bin="$(command -v fish || true)"
    if [ -z "$fish_bin" ]; then
        # samo u dry run-u, inače bi install_fish već prekinuo skriptu
        echo "chsh    (fish još nije instaliran)"
        return
    fi
    if [ "$(uname -s)" = "Darwin" ]; then
        login_shell="$(dscl . -read "/Users/$(id -un)" UserShell | awk '{print $2}')"
    else
        login_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
    fi
    if [ "$(basename "$login_shell")" = "fish" ]; then
        echo "ok      login shell je već $login_shell"
        return
    fi
    # chsh odbija shell koji nije u /etc/shells (brew ga ne upisuje sam)
    if ! grep -qx "$fish_bin" /etc/shells; then
        echo "dodajem $fish_bin u /etc/shells"
        run sudo sh -c "echo '$fish_bin' >> /etc/shells"
    fi
    echo "chsh    $login_shell -> $fish_bin (važi od sledećeg logina)"
    run chsh -s "$fish_bin"
}

INSTALL_FISH=0
groups=()
for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY_RUN=1 ;;
        --install-fish) INSTALL_FISH=1 ;;
        -h|--help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        base|tmux|fish|i3|zed|claude|claude-work) groups+=("$arg") ;;
        *) echo "Nepoznat argument: $arg (grupe: base tmux fish i3 zed claude claude-work)" >&2; exit 1 ;;
    esac
done

if [ "${#groups[@]}" -eq 0 ]; then
    groups=(base fish zed claude)
fi

# --install-fish podrazumeva i linkovanje fish config-a
if [ "$INSTALL_FISH" -eq 1 ]; then
    case " ${groups[*]} " in
        *" fish "*) ;;
        *) groups+=(fish) ;;
    esac
fi

if [ "$DRY_RUN" -eq 1 ]; then echo "(dry run, ništa se ne menja)"; fi
if [ "$INSTALL_FISH" -eq 1 ]; then install_fish; fi
for g in "${groups[@]}"; do
    echo "== $g"
    "group_${g//-/_}"
done
if [ "$INSTALL_FISH" -eq 1 ]; then default_shell_fish; fi

cat <<EOF

Gotovo. Šta ova skripta ne radi:
  - fish instalacija i login shell: ./install.sh --install-fish
  - i3 desktop (paketi, linkovi, GDM sesija): ./install-i3.sh
  - Mac (brew paketi + fish, tmux, zed): ./install-mac.sh
  - 'claude' login pre korišćenja Claude Code-a (sekcija 7)
EOF
