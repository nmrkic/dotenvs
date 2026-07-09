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

Setup skripta (pokreni sa novog checkout-a, iz `~/tools/dotenvs`):

```sh
REPO="$HOME/tools/dotenvs"

# top-level dotfiles
ln -sf "$REPO/.conkyrc"      ~/.conkyrc
ln -sf "$REPO/.vimrc"        ~/.vimrc
ln -sf "$REPO/.Xresources"   ~/.Xresources
ln -sf "$REPO/.tmux.conf"    ~/.tmux.conf
ln -sf "$REPO/.tmate.conf"   ~/.tmate.conf

# fish (ceo direktorijum, fish sam piše fish_variables/completions unutra)
ln -sfn "$REPO/.config/fish" ~/.config/fish

# i3
mkdir -p ~/.config/i3
ln -sf  "$REPO/.config/i3/config"  ~/.config/i3/config
ln -sfn "$REPO/.config/i3/scripts" ~/.config/i3/scripts

# rofi / picom / polybar / dunst
mkdir -p ~/.config/rofi ~/.config/picom ~/.config/polybar ~/.config/dunst
ln -sf  "$REPO/.config/rofi/config.rasi"    ~/.config/rofi/config.rasi
ln -sf  "$REPO/.config/picom/picom.conf"    ~/.config/picom/picom.conf
ln -sf  "$REPO/.config/polybar/config.ini"  ~/.config/polybar/config.ini
ln -sf  "$REPO/.config/polybar/launch.sh"   ~/.config/polybar/launch.sh
ln -sfn "$REPO/.config/polybar/scripts"     ~/.config/polybar/scripts
ln -sf  "$REPO/.config/dunst/dunstrc"       ~/.config/dunst/dunstrc

# arandr monitor layout skripte
ln -sfn "$REPO/.screenlayout" ~/.screenlayout

# i3-x11 wrapper (forsira X11 sesiju, vidi sekciju 4)
mkdir -p ~/.local/bin ~/.local/share/xsessions
ln -sf "$REPO/.local/bin/i3-x11"              ~/.local/bin/i3-x11
ln -sf "$REPO/.local/share/xsessions/i3.desktop" ~/.local/share/xsessions/i3.desktop
```

Fajlovi ispod `system/` u ovom repou **nisu** symlink-ovani (žive van `$HOME`,
vlasnik je `root`) — to su samo referentni snapshot-ovi za sistemske fajlove;
instaliraju se ručno, vidi sekciju 4.

## 3. Šta je gde (mapa)

| U repou | Symlink na | Šta radi |
|---|---|---|
| `.config/i3/config` | `~/.config/i3/config` | glavni i3 config |
| `.config/i3/scripts/` | `~/.config/i3/scripts` | `layout-notify` (najava promene keyboard layout-a u dunst-u) i `i3-confirm-power.sh` (potvrda gašenja/restarta) |
| `.config/fish/` | `~/.config/fish` | fish config, funkcije, `fish_plugins` (fisher) |
| `.config/rofi/config.rasi` | `~/.config/rofi/config.rasi` | rofi tema/layout |
| `.config/polybar/` | `~/.config/polybar/*` | polybar bar config + `launch.sh` + scripts (npr. `eth-ip.sh`) |
| `.config/dunst/dunstrc` | `~/.config/dunst/dunstrc` | izgled/tajmauti notifikacija |
| `.config/picom/picom.conf` | `~/.config/picom/picom.conf` | compositor (transparentnost, senke) |
| `.screenlayout/*.sh` | `~/.screenlayout/*.sh` | arandr layout skripte (vidi sekciju 5) |
| `.local/bin/i3-x11` | `~/.local/bin/i3-x11` | wrapper koji forsira X11 sesiju pre `exec i3` |
| `.local/share/xsessions/i3.desktop` | `~/.local/share/xsessions/i3.desktop` | user-level xsession entry (vidi sekciju 4 — GDM ovaj *ne* čita pre login-a, ostavljen za slučaj drugog display managera) |
| `system/usr/share/xsessions/i3.desktop` | *(ručno kopirati, sudo)* | **stvarni** xsession entry koji GDM koristi |
| `system/usr/local/bin/google-chrome` | *(ručno kopirati, sudo)* | wrapper sa GPU/WebRTC flag-ovima za Chrome |
| `.conkyrc`, `.vimrc`, `.Xresources`, `.tmux.conf`, `.tmate.conf` | `~/...` | standardni dotfile-ovi |

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
