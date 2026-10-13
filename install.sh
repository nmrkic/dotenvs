#!/usr/bin/env bash
# Links the dotfiles from this repo into $HOME.
#
# Safe to re-run: correct links are skipped, and anything else already at the
# target is moved to <name>.bak-<date> before linking.
#
#   ./install.sh              all groups for this OS
#   ./install.sh zed claude   only the listed groups
#   ./install.sh -n [groups]  only print what it would do
#   ./install.sh --install-fish [groups]
#                             install fish before linking if it is missing, and
#                             make it the login shell afterwards (asks for sudo)
#
# Groups: base vim tmux fish i3 zed mac claude claude-work
# By default base (which includes vim and tmux), fish, zed and claude are linked.
# The i3 group is linked only when named explicitly; the whole i3 desktop
# (packages + links + GDM) is set up by ./install-i3.sh, and the Mac (brew +
# fish, tmux, zed) by ./install-mac.sh. claude-work links the same Claude config
# into ~/.claude-work (work account, CLAUDE_CONFIG_DIR) and is also only linked
# when named. Same for mac (AeroSpace, Ghostty), which install-mac.sh includes.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0

run() {
    if [ "$DRY_RUN" -eq 0 ]; then "$@"; fi
}

# link <path in the repo> [path in $HOME, if different]
link() {
    local src="$REPO/$1" dst="$HOME/${2:-$1}"
    if [ ! -e "$src" ]; then
        echo "MISSING $src"
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
    link .tmate.conf
    link .gitconfig
    group_vim
    group_tmux
}

group_vim() {
    link .vimrc
}

group_tmux() {
    link .tmux.conf
}

group_fish() {
    if [ "$(uname -s)" = "Darwin" ]; then
        # conf.d and fish_variables are tied to the Linux machine (virtualfish,
        # rustup, universal variables), so on Mac files are linked one by one
        link .config/fish/config.fish
        link .config/fish/functions
        link .config/fish/fish_plugins
    else
        # the whole directory, fish writes fish_variables/completions into it itself
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

group_mac() {
    link mac/.aerospace.toml .aerospace.toml
    link mac/ghostty/config  .config/ghostty/config
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
    echo "== installing fish"
    if command -v fish >/dev/null 2>&1; then
        echo "ok      fish is already installed ($(command -v fish))"
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
        echo "No apt/dnf/pacman/brew, install fish by hand and run again." >&2
        exit 1
    fi
}

default_shell_fish() {
    echo "== fish as the login shell"
    local fish_bin login_shell
    fish_bin="$(command -v fish || true)"
    if [ -z "$fish_bin" ]; then
        # only in a dry run, otherwise install_fish would already have stopped the script
        echo "chsh    (fish is not installed yet)"
        return
    fi
    if [ "$(uname -s)" = "Darwin" ]; then
        login_shell="$(dscl . -read "/Users/$(id -un)" UserShell | awk '{print $2}')"
    else
        login_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
    fi
    if [ "$(basename "$login_shell")" = "fish" ]; then
        echo "ok      login shell is already $login_shell"
        return
    fi
    # chsh refuses a shell that isn't in /etc/shells (brew doesn't add it itself)
    if ! grep -qx "$fish_bin" /etc/shells; then
        echo "adding  $fish_bin to /etc/shells"
        run sudo sh -c "echo '$fish_bin' >> /etc/shells"
    fi
    echo "chsh    $login_shell -> $fish_bin (takes effect at the next login)"
    run chsh -s "$fish_bin"
}

INSTALL_FISH=0
groups=()
for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY_RUN=1 ;;
        --install-fish) INSTALL_FISH=1 ;;
        -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        base|vim|tmux|fish|i3|zed|mac|claude|claude-work) groups+=("$arg") ;;
        *) echo "Unknown argument: $arg (groups: base vim tmux fish i3 zed mac claude claude-work)" >&2; exit 1 ;;
    esac
done

if [ "${#groups[@]}" -eq 0 ]; then
    groups=(base fish zed claude)
fi

# --install-fish implies linking the fish config too
if [ "$INSTALL_FISH" -eq 1 ]; then
    case " ${groups[*]} " in
        *" fish "*) ;;
        *) groups+=(fish) ;;
    esac
fi

if [ "$DRY_RUN" -eq 1 ]; then echo "(dry run, nothing is changed)"; fi
if [ "$INSTALL_FISH" -eq 1 ]; then install_fish; fi
for g in "${groups[@]}"; do
    echo "== $g"
    "group_${g//-/_}"
done
if [ "$INSTALL_FISH" -eq 1 ]; then default_shell_fish; fi

cat <<EOF

Done. What this script doesn't do:
  - fish install and login shell: ./install.sh --install-fish
  - i3 desktop (packages, links, GDM session): ./install-i3.sh
  - Mac (brew packages + fish, tmux, zed): ./install-mac.sh
  - 'claude' login before using Claude Code (section 7)
EOF
