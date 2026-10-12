#!/usr/bin/env bash
# Podiže Mac: instalira fish, tmux i Zed, linkuje njihove config-e iz ovog
# repoa i postavlja fish kao login shell. Claude Code se podešava samo za
# poslovni nalog (~/.claude-work), lični ~/.claude se ne dira.
#
# Sa Homebrew-om sve ide preko brew-a. Bez njega se tmux i fish kompajliraju iz
# source-a u ~/.local (treba samo Xcode Command Line Tools), a Zed se preskače.
# Ako korisnik nije admin, umesto chsh se fish pokreće iz ~/.zshrc.
#
# Bezbedno za ponovno pokretanje: ono što je već instalirano ili linkovano se
# preskače.
#
#   ./install-mac.sh       instaliraj i podesi
#   ./install-mac.sh -n    samo ispiši šta bi uradio
#
# Ostale grupe (base, claude) se po želji dodaju posle: ./install.sh base
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0

run() {
    if [ "$DRY_RUN" -eq 0 ]; then "$@"; fi
}

for arg in "$@"; do
    case "$arg" in
        -n|--dry-run) DRY_RUN=1 ;;
        -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Nepoznat argument: $arg" >&2; exit 1 ;;
    esac
done

if [ "$(uname -s)" != "Darwin" ]; then
    echo "Ova skripta je samo za macOS." >&2
    exit 1
fi

# build iz source-a, kad nema brew-a
PREFIX="$HOME/.local"
SRC="$PREFIX/src"
DEPS="$SRC/deps"    # libevent i utf8proc, statički, samo za build tmux-a
LIBEVENT_VERSION=2.1.13-stable
UTF8PROC_VERSION=2.12.0
TMUX_VERSION=3.8
FISH_VERSION=4.9.3
JOBS="$(sysctl -n hw.ncpu)"

# fetch <url>: skine arhivu i raspakuje je u $SRC
fetch() {
    mkdir -p "$SRC"
    curl -fsSL "$1" | tar -xf - -C "$SRC"
}

build_tmux() {
    if command -v tmux >/dev/null 2>&1; then
        echo "ok      tmux je već instaliran ($(command -v tmux))"
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

    # macOS wcwidth loše računa širinu Unicode znakova, tmux zato traži utf8proc
    fetch "https://github.com/JuliaStrings/utf8proc/archive/refs/tags/v$UTF8PROC_VERSION.tar.gz"
    (cd "$SRC/utf8proc-$UTF8PROC_VERSION" \
        && make libutf8proc.a \
        && cp utf8proc.h "$DEPS/include/" && cp libutf8proc.a "$DEPS/lib/")

    # bez pkg-config-a configure nalazi biblioteke preko CPPFLAGS/LDFLAGS
    fetch "https://github.com/tmux/tmux/releases/download/$TMUX_VERSION/tmux-$TMUX_VERSION.tar.gz"
    (cd "$SRC/tmux-$TMUX_VERSION" \
        && ./configure --prefix="$PREFIX" --enable-utf8proc --disable-jemalloc \
            CPPFLAGS="-I$DEPS/include" LDFLAGS="-L$DEPS/lib" \
        && make -j"$JOBS" && make install)
}

build_fish() {
    if command -v fish >/dev/null 2>&1; then
        echo "ok      fish je već instaliran ($(command -v fish))"
        return
    fi
    echo "build   fish $FISH_VERSION -> $PREFIX/bin (cargo)"
    if [ "$DRY_RUN" -eq 1 ]; then return; fi
    # rustup ide u ~/.cargo i ~/.rustup, PATH se ne dira jer cargo treba samo ovde
    if ! command -v rustup >/dev/null 2>&1; then
        curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal
    fi
    # fish traži noviji Rust (edition 2024) od onog koji je možda već instaliran
    rustup toolchain install stable --profile minimal
    fetch "https://github.com/fish-shell/fish-shell/releases/download/$FISH_VERSION/fish-$FISH_VERSION.tar.xz"
    # bez sphinx-a i msgfmt-a build samo preskoči man stranice i prevode
    (cd "$SRC/fish-$FISH_VERSION" && cargo +stable build --release --locked)
    mkdir -p "$PREFIX/bin"
    for bin in fish fish_indent fish_key_reader; do
        cp "$SRC/fish-$FISH_VERSION/target/release/$bin" "$PREFIX/bin/"
    done
}

# bez admina nema upisa u /etc/shells, pa ni chsh-a: zsh ostaje login shell i
# odmah prepušta terminal fish-u. SHELL=fish da tmux otvara fish, a ručno
# pokrenut zsh ne skače nazad u fish.
ZSHRC_MARK="# dotenvs: fish bez chsh"
zshrc_fish() {
    echo "== fish iz ~/.zshrc (nisi admin, chsh ne može)"
    if grep -qxF "$ZSHRC_MARK" "$HOME/.zshrc" 2>/dev/null; then
        echo "ok      ~/.zshrc već pokreće fish"
        return
    fi
    echo "dopuna  ~/.zshrc"
    if [ "$DRY_RUN" -eq 1 ]; then return; fi
    cat >>"$HOME/.zshrc" <<'ZSH'

# dotenvs: fish bez chsh
export PATH="$HOME/.local/bin:$PATH"
if [[ -o interactive && $SHELL != */fish && -x $HOME/.local/bin/fish ]]; then
    export SHELL=$HOME/.local/bin/fish
    exec $SHELL -l
fi
ZSH
}

if [ "$DRY_RUN" -eq 1 ]; then echo "(dry run, ništa se ne menja)"; fi

if command -v brew >/dev/null 2>&1; then
    echo "== brew paketi"
    if command -v tmux >/dev/null 2>&1; then
        echo "ok      tmux je već instaliran ($(command -v tmux))"
    else
        echo "install tmux (brew)"
        run brew install tmux
    fi
    if [ -d /Applications/Zed.app ] || command -v zed >/dev/null 2>&1; then
        echo "ok      Zed je već instaliran"
    else
        echo "install zed (brew cask)"
        run brew install --cask zed
    fi
else
    echo "== build iz source-a (nema brew-a)"
    if ! xcode-select -p >/dev/null 2>&1; then
        cat >&2 <<'MSG'
Nema Xcode Command Line Tools (clang, make). Instaliraj ih pa pokreni ponovo:
  xcode-select --install
MSG
        exit 1
    fi
    # da install.sh i provere ispod vide ono što je već kompajlirano
    export PATH="$PREFIX/bin:$HOME/.cargo/bin:$PATH"
    build_tmux
    build_fish
    echo "skip    Zed (bez brew-a): skini ga sa https://zed.dev/download"
fi

# fish: instalacija, linkovi i chsh su u install.sh, da postoje na jednom mestu.
# chsh traži sudo, pa ga ne-admin preskače i dobija fish preko ~/.zshrc.
if id -Gn | tr ' ' '\n' | grep -qx admin; then
    flags=(--install-fish)
else
    flags=(fish)
fi
if [ "$DRY_RUN" -eq 1 ]; then
    "$REPO/install.sh" -n "${flags[@]}" tmux zed claude-work | sed -e '1d' -e '/^$/,$d'
else
    "$REPO/install.sh" "${flags[@]}" tmux zed claude-work | sed '/^$/,$d'
fi
if [ "${flags[0]}" = fish ]; then zshrc_fish; fi

cat <<'MSG'

Gotovo. Otvori nov terminal da fish postane aktivan (pokrenuće i tmux).
Ručno ostaje:
  - Claude login za poslovni nalog: pokreni 'ccw' (claude sa ~/.claude-work)
  - u Zed-u biraj agenta "Claude Work"; "Claude Personal" ostaje na spisku jer
    je settings.json zajednički, ali bez logina u ~/.claude ne radi
  - yabai/skhd config je u mac/, ne linkuje se automatski
MSG
