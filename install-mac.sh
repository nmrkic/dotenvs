#!/usr/bin/env bash
# Podiže Mac: preko Homebrew-a instalira fish, tmux i Zed, linkuje njihove
# config-e iz ovog repoa i postavlja fish kao login shell. Claude Code se
# podešava samo za poslovni nalog (~/.claude-work), lični ~/.claude se ne dira.
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
        -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Nepoznat argument: $arg" >&2; exit 1 ;;
    esac
done

if [ "$(uname -s)" != "Darwin" ]; then
    echo "Ova skripta je samo za macOS." >&2
    exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
    cat >&2 <<'MSG'
Homebrew nije instaliran. Instaliraj ga pa pokreni skriptu ponovo:
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
MSG
    exit 1
fi

if [ "$DRY_RUN" -eq 1 ]; then echo "(dry run, ništa se ne menja)"; fi

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

# fish: instalacija, linkovi i chsh su u install.sh, da postoje na jednom mestu
if [ "$DRY_RUN" -eq 1 ]; then
    "$REPO/install.sh" -n --install-fish tmux zed claude-work | sed -e '1d' -e '/^$/,$d'
else
    "$REPO/install.sh" --install-fish tmux zed claude-work | sed '/^$/,$d'
fi

cat <<'MSG'

Gotovo. Otvori nov terminal da fish postane aktivan (pokrenuće i tmux).
Ručno ostaje:
  - Claude login za poslovni nalog: pokreni 'ccw' (claude sa ~/.claude-work)
  - u Zed-u biraj agenta "Claude Work"; "Claude Personal" ostaje na spisku jer
    je settings.json zajednički, ali bez logina u ~/.claude ne radi
  - yabai/skhd config je u mac/, ne linkuje se automatski
MSG
