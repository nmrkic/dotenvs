#!/usr/bin/env bash
# Sets up a Mac: installs fish, tmux and Zed, links their configs (plus .vimrc,
# AeroSpace, Ghostty) from this repo and makes fish the login shell. Claude Code
# is configured only for the work account (~/.claude-work), the personal
# ~/.claude is left alone.
#
# With --admin everything goes through Homebrew (installed if missing): fish,
# tmux, fzf, Zed and AeroSpace, then chsh to fish. Anything built from source
# earlier (~/.local/bin, ~/.local/src, Rust in ~/.rustup and ~/.cargo) is
# deleted, along with the ~/.zshrc block that started fish.
# Without --admin tmux and fish are built from source into ~/.local (needs only
# the Xcode Command Line Tools), Zed and AeroSpace are skipped, and fish is
# started from ~/.zshrc because chsh needs an admin.
#
# Safe to re-run: anything already installed or linked is skipped.
#
#   ./install-mac.sh --admin      via brew (asks for your password)
#   ./install-mac.sh              no admin rights, build from source
#   ./install-mac.sh -n [--admin] only print what it would do
#
# Other groups (base, claude) can be added afterwards: ./install.sh base
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
ADMIN=0

run() {
    if [ "$DRY_RUN" -eq 0 ]; then "$@"; fi
}

for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY_RUN=1 ;;
        -a|--admin) ADMIN=1 ;;
        -h|--help) sed -n '2,21p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown argument: $arg" >&2; exit 1 ;;
    esac
done

if [ "$(uname -s)" != "Darwin" ]; then
    echo "This script is for macOS only." >&2
    exit 1
fi

if [ "$ADMIN" -eq 1 ] && ! id -Gn | tr ' ' '\n' | grep -qx admin; then
    echo "--admin: user $(id -un) is not in the admin group, run without --admin." >&2
    exit 1
fi

# build from source, when there is no brew
PREFIX="$HOME/.local"
SRC="$PREFIX/src"
DEPS="$SRC/deps"    # libevent and utf8proc, static, only for building tmux
LIBEVENT_VERSION=2.1.13-stable
UTF8PROC_VERSION=2.12.0
TMUX_VERSION=3.8
FISH_VERSION=4.9.3
JOBS="$(sysctl -n hw.ncpu)"

# fetch <url>: downloads an archive and unpacks it into $SRC
fetch() {
    mkdir -p "$SRC"
    curl -fsSL "$1" | tar -xf - -C "$SRC"
}

build_tmux() {
    if command -v tmux >/dev/null 2>&1; then
        echo "ok      tmux is already installed ($(command -v tmux))"
        return
    fi
    echo "build   tmux $TMUX_VERSION -> $PREFIX/bin (libevent $LIBEVENT_VERSION, utf8proc $UTF8PROC_VERSION)"
    if [ "$DRY_RUN" -eq 1 ]; then return; fi
    mkdir -p "$DEPS/include" "$DEPS/lib"

    fetch "https://github.com/libevent/libevent/releases/download/release-$LIBEVENT_VERSION/libevent-$LIBEVENT_VERSION.tar.gz"
    (cd "$SRC/libevent-$LIBEVENT_VERSION" \
        && ./configure --prefix="$DEPS" --disable-shared --disable-openssl \
            --disable-samples --disable-libevent-regress \
        && make -j"$JOBS" && make install)

    # macOS wcwidth gets the width of Unicode characters wrong, so tmux wants utf8proc
    fetch "https://github.com/JuliaStrings/utf8proc/archive/refs/tags/v$UTF8PROC_VERSION.tar.gz"
    (cd "$SRC/utf8proc-$UTF8PROC_VERSION" \
        && make libutf8proc.a \
        && cp utf8proc.h "$DEPS/include/" && cp libutf8proc.a "$DEPS/lib/")

    # without pkg-config, configure finds the libraries via CPPFLAGS/LDFLAGS
    fetch "https://github.com/tmux/tmux/releases/download/$TMUX_VERSION/tmux-$TMUX_VERSION.tar.gz"
    (cd "$SRC/tmux-$TMUX_VERSION" \
        && ./configure --prefix="$PREFIX" --enable-utf8proc --disable-jemalloc \
            CPPFLAGS="-I$DEPS/include" LDFLAGS="-L$DEPS/lib" \
        && make -j"$JOBS" && make install)
}

build_fish() {
    if command -v fish >/dev/null 2>&1; then
        echo "ok      fish is already installed ($(command -v fish))"
        return
    fi
    echo "build   fish $FISH_VERSION -> $PREFIX/bin (cargo)"
    if [ "$DRY_RUN" -eq 1 ]; then return; fi
    # rustup goes into ~/.cargo and ~/.rustup, PATH is left alone since cargo is only needed here
    if ! command -v rustup >/dev/null 2>&1; then
        curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal
    fi
    # fish needs a newer Rust (edition 2024) than one that may already be installed
    rustup toolchain install stable --profile minimal
    fetch "https://github.com/fish-shell/fish-shell/releases/download/$FISH_VERSION/fish-$FISH_VERSION.tar.xz"
    # without sphinx and msgfmt the build just skips man pages and translations
    (cd "$SRC/fish-$FISH_VERSION" && cargo +stable build --release --locked)
    mkdir -p "$PREFIX/bin"
    for bin in fish fish_indent fish_key_reader; do
        cp "$SRC/fish-$FISH_VERSION/target/release/$bin" "$PREFIX/bin/"
    done
}

# without admin there is no writing to /etc/shells, so no chsh either: zsh stays
# the login shell and hands the terminal straight to fish. SHELL=fish so tmux
# opens fish, and a zsh started by hand doesn't jump back into fish.
ZSHRC_MARK="# dotenvs: fish without chsh"
# the same block from before the README was translated, recognized so it isn't
# added twice and so --admin still removes it
ZSHRC_MARK_OLD="# dotenvs: fish bez chsh"

# zshrc_has_fish: prints the marker of the fish block in ~/.zshrc, if there is one
zshrc_has_fish() {
    local mark
    for mark in "$ZSHRC_MARK" "$ZSHRC_MARK_OLD"; do
        if grep -qxF "$mark" "$HOME/.zshrc" 2>/dev/null; then
            echo "$mark"
            return 0
        fi
    done
    return 1
}

zshrc_fish() {
    echo "== fish from ~/.zshrc (not admin, chsh is not possible)"
    if zshrc_has_fish >/dev/null; then
        echo "ok      ~/.zshrc already starts fish"
        return
    fi
    echo "append  ~/.zshrc"
    if [ "$DRY_RUN" -eq 1 ]; then return; fi
    cat >>"$HOME/.zshrc" <<'ZSH'

# dotenvs: fish without chsh
export PATH="$HOME/.local/bin:$PATH"
if [[ -o interactive && $SHELL != */fish && -x $HOME/.local/bin/fish ]]; then
    export SHELL=$HOME/.local/bin/fish
    exec $SHELL -l
fi
ZSH
}

BREW=/opt/homebrew/bin/brew

install_brew() {
    echo "== Homebrew"
    if [ -x "$BREW" ]; then
        echo "ok      brew is already installed ($BREW)"
    else
        echo "install Homebrew -> /opt/homebrew"
        run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    # PATH for the rest of the script and for install.sh (chsh to brew's fish)
    if [ -x "$BREW" ]; then eval "$("$BREW" shellenv)"; fi
}

# brew_formula <name>
brew_formula() {
    if brew list --formula "$1" >/dev/null 2>&1; then
        echo "ok      $1 (brew)"
    else
        echo "install $1 (brew)"
        run brew install "$1"
    fi
}

# brew_cask <cask> <name of the .app in /Applications>
brew_cask() {
    if [ -d "/Applications/$2.app" ]; then
        echo "ok      $2"
    else
        echo "install $2 (brew cask)"
        run brew install --cask "$1"
    fi
}

# rm_old <path>: deletes a leftover of the source build, if it exists
rm_old() {
    if [ -e "$1" ] || [ -L "$1" ]; then
        echo "delete  $1"
        run rm -rf "$1"
    fi
}

# with brew there is no need for fish/tmux built into ~/.local, nor for Rust,
# which was only there to build fish. ~/.local/bin stays (claude lives there too).
remove_source_builds() {
    echo "== removing the source builds"
    local bin
    for bin in fish fish_indent fish_key_reader tmux; do rm_old "$PREFIX/bin/$bin"; done
    rm_old "$SRC"
    rm_old "$PREFIX/share/man/man1/tmux.1"
    rm_old "$HOME/.rustup"
    rm_old "$HOME/.cargo"
}

# after chsh, ~/.zshrc no longer needs to start fish (and it would point to the
# deleted ~/.local/bin/fish)
remove_zshrc_fish() {
    local mark
    if mark="$(zshrc_has_fish)"; then
        echo "delete  fish block from ~/.zshrc (backup ~/.zshrc.bak-$(date +%Y%m%d-%H%M%S))"
        run cp "$HOME/.zshrc" "$HOME/.zshrc.bak-$(date +%Y%m%d-%H%M%S)"
        run sed -i '' "/^$mark\$/,/^fi\$/d" "$HOME/.zshrc"
    fi
}

if [ "$DRY_RUN" -eq 1 ]; then echo "(dry run, nothing is changed)"; fi

if [ "$ADMIN" -eq 1 ]; then
    install_brew
    remove_source_builds
    echo "== brew packages"
    for f in fish tmux fzf; do brew_formula "$f"; done
    brew_cask zed Zed
    brew_cask nikitabobko/tap/aerospace AeroSpace
    remove_zshrc_fish
else
    echo "== build from source (no --admin)"
    if ! xcode-select -p >/dev/null 2>&1; then
        cat >&2 <<'MSG'
No Xcode Command Line Tools (clang, make). Install them and run again:
  xcode-select --install
MSG
        exit 1
    fi
    # so install.sh and the checks below see what has already been built
    export PATH="$PREFIX/bin:$HOME/.cargo/bin:$PATH"
    build_tmux
    build_fish
    echo "skip    Zed and AeroSpace (no --admin): get Zed from https://zed.dev/download"
fi

# fish: install, links and chsh live in install.sh, so they exist in one place.
# chsh needs sudo, so a non-admin skips it and gets fish via ~/.zshrc.
if [ "$ADMIN" -eq 1 ]; then
    flags=(--install-fish)
else
    flags=(fish)
fi
if [ "$DRY_RUN" -eq 1 ]; then
    "$REPO/install.sh" -n "${flags[@]}" vim tmux zed mac claude-work | sed -e '1d' -e '/^$/,$d'
else
    "$REPO/install.sh" "${flags[@]}" vim tmux zed mac claude-work | sed '/^$/,$d'
fi
if [ "$ADMIN" -eq 0 ]; then zshrc_fish; fi

cat <<'MSG'

Done. Open a new terminal so fish becomes active (it starts tmux too).
Left to do by hand:
  - Claude login for the work account: run 'ccw' (claude with ~/.claude-work)
  - in Zed pick the "Claude Work" agent; "Claude Personal" stays in the list
    because settings.json is shared, but it doesn't work without a login in ~/.claude
  - AeroSpace: start it once and give it Accessibility (Privacy & Security)
  - keyboard, so the AeroSpace shortcuts (alt = Start key) work like i3:
      System Settings → Keyboard → Keyboard Shortcuts → Modifier Keys: pick the
      external keyboard and swap Command ⌘ and Option ⌥ (skip this if Karabiner
      is installed, its first rule already does the swap)
      System Settings → Keyboard → Keyboard Shortcuts → Spotlight: move
      "Show Spotlight search" to ⌥Space
  - yabai/skhd: the config is in mac/, but it is neither installed nor linked.
    yabai needs SIP disabled to work fully; AeroSpace (mac/.aerospace.toml) replaces it
  - Karabiner-Elements: deliberately not installed for now. mac/karabiner/ holds
    Linux-style shortcuts (Ctrl+C/V -> ⌘C/V outside terminals, Ctrl+Shift+C/V in
    terminals, Ctrl+arrows, Home/End); revisit only if the native ⌘ shortcuts
    don't stick. It needs admin and approving a driver (system extension).
MSG
