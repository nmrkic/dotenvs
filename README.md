# dotenvs

Moji dotfiles i konfiguracija za i3 desktop setup (Ubuntu, GDM3 kao display manager,
X11 sesija). Ovaj README opisuje šta treba instalirati i linkovati da bi sve radilo
na novom sistemu.

## 1. Paketi koje treba instalirati

```sh
sudo apt install \
    i3 \
    fish \
    rofi \
    polybar \
    dunst \
    picom \
    feh \
    conky-all \
    dex \
    network-manager-gnome \
    numlockx \
    flameshot \
    brightnessctl \
    pulseaudio-utils \
    arandr \
    x11-xserver-utils \
    x11-xkb-utils \
    gnome-settings-daemon
```

Napomene:
- `gnome-settings-daemon` daje `/usr/libexec/gsd-xsettings` (font/theme/cursor
  settings za GTK app-ove pod i3).
- `dex` pokreće `.desktop` autostart entries (`exec --no-startup-id dex --autostart
  --environment i3` u i3 config-u).
- Za fish shell plugin manager (**fisher**) instalacija ide kroz fish samog, ne apt:
  ```fish
  curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
  fisher update   # povuče sve iz fish_plugins
  ```
- Postaviti fish kao login shell: `chsh -s /usr/bin/fish`

## 2. Symlink-ovanje

Konvencija u ovom repou: **fajl** (ili samostalan pod-direktorijum poput
`scripts/`) živi u repou, a na stvarnoj lokaciji u `$HOME` stoji symlink ka njemu.
Roditeljski direktorijumi (`.config/i3`, `.config/rofi`...) su obični direktorijumi,
ne symlink-ovi — tako generisani/cache fajlovi koje alati prave pored config-a ne
ulaze u git.

Sve linkove pravi `install.sh` (repo može biti kloniran bilo gde, skripta
linkuje ka mestu na kom se sama nalazi):

```sh
git clone <repo-url> ~/tools/dotenvs
cd ~/tools/dotenvs
./install.sh -n           # samo ispiše šta bi uradio
./install.sh              # sve grupe za ovaj OS
./install.sh zed claude   # samo navedene grupe
./install.sh --install-fish   # sve + instalira fish i postavi ga kao login shell
```

Grupe su `base` (vim, tmux, tmate, git), `fish`, `i3` (i3, rofi, picom, polybar,
dunst, conky, `.screenlayout`, i3-x11 wrapper), `zed` i `claude`. Na Linuxu se
podrazumevano linkuju sve, na macOS-u samo `base`, `zed` i `claude`.

Skripta se može pokretati više puta: ispravan link preskače (`ok`), a ako na
ciljnoj lokaciji već postoji nešto drugo, prvo ga premesti u
`<ime>.bak-<datum>` pa tek onda linkuje. Ništa ne briše i ne koristi `sudo`.

`--install-fish` je jedini deo koji traži lozinku: ako fish nije instaliran,
instalira ga preko `apt`/`dnf`/`pacman`/`brew`, linkuje fish config i na kraju
uradi `chsh` (po potrebi prvo upiše fish u `/etc/shells`). Ako je fish već
instaliran i već je login shell, ne radi ništa.

Kad se u repo doda nov fajl koji treba linkovati, dodaje se jedna `link` linija
u odgovarajuću grupu u `install.sh` i red u tabelu u sekciji 3.

**Za AI agenta:** na novom računaru pokreni `./install.sh -n`, pokaži izlaz, pa
`./install.sh`. Ne pravi linkove ručno i ne briši `.bak-*` fajlove bez pitanja.
Pakete (sekcija 1) i `system/` fajlove (sekcija 4) instaliraj samo ako se to
izričito traži, jer zahtevaju `sudo`.

Fajlovi ispod `system/` u ovom repou **nisu** symlink-ovani (žive van `$HOME`,
vlasnik je `root`) — to su samo referentni snapshot-ovi za sistemske fajlove;
instaliraju se ručno, vidi sekciju 4.

## 3. Šta je gde (mapa)

| U repou | Symlink na | Šta radi |
|---|---|---|
| `.config/i3/config` | `~/.config/i3/config` | glavni i3 config |
| `.config/i3/scripts/` | `~/.config/i3/scripts` | `layout-notify` (najava promene keyboard layout-a u dunst-u), `keyboard-layout.sh` (postavlja layout-e i vraća ih kad USB switch ponovo priključi tastaturu) i `i3-confirm-power.sh` (potvrda gašenja/restarta) |
| `.config/fish/` | `~/.config/fish` | fish config, funkcije, `fish_plugins` (fisher) |
| `.config/rofi/config.rasi` | `~/.config/rofi/config.rasi` | rofi tema/layout |
| `.config/polybar/` | `~/.config/polybar/*` | polybar bar config + `launch.sh` + scripts (npr. `eth-ip.sh`) |
| `.config/dunst/dunstrc` | `~/.config/dunst/dunstrc` | izgled/tajmauti notifikacija |
| `.config/picom/picom.conf` | `~/.config/picom/picom.conf` | compositor (transparentnost, senke) |
| `.config/zed/settings.json`, `keymap.json` | `~/.config/zed/*` | Zed podešavanja i prečice; agent "Claude Work" ima upisanu putanju `/home/nebojsa/.claude-work` |
| `.screenlayout/*.sh` | `~/.screenlayout/*.sh` | arandr layout skripte (vidi sekciju 5) |
| `.local/bin/i3-x11` | `~/.local/bin/i3-x11` | wrapper koji forsira X11 sesiju pre `exec i3` |
| `.local/share/xsessions/i3.desktop` | `~/.local/share/xsessions/i3.desktop` | user-level xsession entry (vidi sekciju 4 — GDM ovaj *ne* čita pre login-a, ostavljen za slučaj drugog display managera) |
| `system/usr/share/xsessions/i3.desktop` | *(ručno kopirati, sudo)* | **stvarni** xsession entry koji GDM koristi |
| `system/usr/local/bin/google-chrome` | *(ručno kopirati, sudo)* | wrapper sa GPU/WebRTC flag-ovima za Chrome |
| `.conkyrc`, `.conky/`, `.vimrc`, `.Xresources`, `.tmux.conf`, `.tmate.conf`, `.gitconfig` | `~/...` | standardni dotfile-ovi |
| `.claude/skills/` | `~/.claude/skills` | globalni Claude Code skill-ovi (ceo direktorijum) |
| `.claude/commands/` | `~/.claude/commands` | globalne slash komande |
| `.claude/settings.json` | `~/.claude/settings.json` | Claude Code podešavanja (permissions, tema) |

## 4. Chrome / X11 fix

Chrome je pravio probleme (crn ekran / loše renderovanje) pod i3-jem jer je
auto-detekcija ozone platforme povremeno hvatala pogrešnu sesiju, i posebno
zbog GPU video-decode/WebRTC putanje na ovoj GPU/driver kombinaciji. Dva dela
fixa:

1. **Forsiranje X11 sesije** — `~/.local/bin/i3-x11` je mali wrapper:
   ```sh
   #!/bin/sh
   export XDG_SESSION_TYPE=x11
   exec /usr/bin/i3 "$@"
   ```
   Sistemski xsession entry `/usr/share/xsessions/i3.desktop` (GDM ovo čita,
   **ne** `~/.local/share/xsessions`) je izmenjen da poziva ovaj wrapper
   umesto direktno `i3`:
   ```
   Exec=/home/nebojsa/.local/bin/i3-x11
   ```
   Original (pre izmene) je u paketu i zove se `i3` — GDM ga instalira ponovo
   pri svakom update-u i3 paketa, pa **ovaj korak treba ponoviti na svakom
   novom sistemu**:
   ```sh
   sudo install -m 644 ~/tools/dotenvs/system/usr/share/xsessions/i3.desktop \
       /usr/share/xsessions/i3.desktop
   ```

2. **GPU/WebRTC flagovi za Chrome** — `/usr/local/bin/google-chrome` je custom
   wrapper koji se poziva umesto `/usr/bin/google-chrome-stable`:
   ```sh
   #!/bin/bash
   /usr/bin/google-chrome-stable \
     --disable-features=WebRtcUseGpuMemoryBuffer \
     --disable-accelerated-video-decode \
     "$@"
   ```
   Instalacija na novom sistemu:
   ```sh
   sudo install -m 755 ~/tools/dotenvs/system/usr/local/bin/google-chrome \
       /usr/local/bin/google-chrome
   ```
   `/usr/local/bin` je ispred `/usr/bin` u `$PATH`-u, tako da ovaj wrapper ima
   prioritet nad pravim binarnim fajlom.

## 5. arandr / monitor layout

`.screenlayout/` sadrži skripte generisane iz **arandr**-a (Preferences →
`arandr`, pa Layout → Save As...) za različite monitor setup-e:

- `monitors.sh` — laptop + 3x monitor preko DP-3-x (docking station #1)
- `monitors-dp2.sh` — isto, ali docking station se javlja kao DP-2-x
- `monitors-hr.sh` — laptop + 1 eksterni monitor (home office)
- `auto-monitors.sh` — bira automatski jedan od gornjih na osnovu toga šta
  `xrandr` javlja kao `connected`; ovo se poziva iz i3 config-a na startup-u
  (`exec --no-startup-id ~/.screenlayout/auto-monitors.sh`)

Kad se promeni monitor setup (nov docking station, nov monitor), pokreni
`arandr`, poduesi raspored, snimi kao novu `.sh` skriptu u `~/.screenlayout/`
(što je symlink na repo), i dodaj granu u `auto-monitors.sh` po istom
obrascu (`xrandr | grep -q "^<output> connected"`).

## 6. Layout indikator (RS/US tastatura)

I3 config na startu petljom rotira layout-e da bi se `xkb` state prijavio i
osvežila statusna traka (`setxkbmap -layout us,rs(latin),rs
-option grp:alt_shift_toggle`), a `.config/i3/scripts/layout-notify` je binarni
program (source u `layout-notify.c`, koristi samo `libX11`/XKBlib — treba
`libx11-dev` paket; kompajlirati sa `gcc -o layout-notify layout-notify.c -lX11`
ako fali binarni fajl na novom sistemu) koji šalje dunst notifikaciju kad se
layout promeni.

## 7. Claude Code

U repou je samo ono što se prenosi sa računara na računar:

- `.claude/skills/` — moji globalni skill-ovi; ceo direktorijum je symlink, pa
  svaki nov skill napravljen u `~/.claude/skills` odmah stoji u repou spreman
  za commit. Claude u isti direktorijum piše i `synced/` (skill-ovi koje sam
  sinhronizuje sa naloga) — taj pod-direktorijum je u `.gitignore`.
- `.claude/commands/` — globalne slash komande; ceo direktorijum je symlink,
  pa sve što se doda u `~/.claude/commands` završi u repou.
- `.claude/settings.json` — podešavanja (permissions allow/deny, tema).

Namerno **nije** u repou:

- `~/.claude.json` — sadrži podatke o nalogu (`oauthAccount`, `userID`,
  `machineID`), istoriju projekata sa lokalnim putanjama i keš; Claude ga stalno
  prepisuje, pa bi symlink ionako bio zamenjen običnim fajlom.
- `~/.claude/.credentials.json` — login token.
- `~/.claude/settings.local.json`, `projects/`, `history.jsonl`, `sessions/` i
  ostalo — stanje vezano za ovaj računar.

Na novom računaru se prvo uradi `claude` login, pa onda symlink-ovi iz sekcije 2.
