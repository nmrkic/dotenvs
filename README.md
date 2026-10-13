# dotenvs

My dotfiles and configuration for an i3 desktop setup (Ubuntu, GDM3 as the display
manager, X11 session). This README describes what to install and link to get
everything working on a new system.

## 1. i3 desktop (packages + GDM session)

i3 doesn't go on every machine, so it has its own script, separate from `install.sh`:

```sh
./install-i3.sh -n    # only print what it would do
./install-i3.sh       # install and configure
```

It works only on Ubuntu/Debian (`apt`) and, in order:

1. installs the missing packages: `i3 i3lock rofi polybar dunst picom feh conky-all
   dex network-manager-gnome numlockx flameshot brightnessctl pulseaudio-utils
   arandr x11-xserver-utils x11-xkb-utils gnome-settings-daemon`
2. links the i3 group (same as `./install.sh i3`)
3. builds `layout-notify` from source if the binary in the repo can't run on
   this system (section 6)
4. writes `/usr/share/xsessions/i3.desktop` with `Exec=$HOME/.local/bin/i3-x11`
   (section 4)

It can be run repeatedly; it asks for `sudo` only when there is something to
install or write. The package list is the `PACKAGES` array at the top of the script.

Notes:
- `gnome-settings-daemon` provides `/usr/libexec/gsd-xsettings` (font/theme/cursor
  settings for GTK apps under i3).
- `dex` runs the `.desktop` autostart entries (`exec --no-startup-id dex --autostart
  --environment i3` in the i3 config).
- Left to do by hand: `snixembed` (not in apt), the wallpaper `~/Pictures/dark-blue.jpg`,
  the Chrome wrapper (section 4) and the monitor layout (section 5).
- fish is installed with `./install.sh --install-fish` (section 2); fisher is already
  in the repo (`.config/fish/functions/fisher.fish`).

## 2. Symlinking

Convention in this repo: the **file** (or a self-contained subdirectory such as
`scripts/`) lives in the repo, and its real location in `$HOME` holds a symlink to it.
Parent directories (`.config/i3`, `.config/rofi`...) are plain directories, not
symlinks, so generated/cache files that tools create next to the config don't end
up in git.

All links are made by `install.sh` (the repo can be cloned anywhere, the script
links to wherever it lives itself):

```sh
git clone <repo-url> ~/tools/dotenvs
cd ~/tools/dotenvs
./install.sh -n           # only print what it would do
./install.sh              # base, fish, zed, claude
./install.sh zed claude   # only the listed groups
./install.sh --install-fish   # same + install fish and make it the login shell
```

The groups are `base` (vim, tmux, tmate, git), `vim` (only `.vimrc`), `tmux` (only
`.tmux.conf`), `fish`, `i3` (i3, rofi, picom, polybar, dunst, conky, `.screenlayout`,
i3-x11 wrapper), `zed`, `mac` (AeroSpace and Ghostty config), `claude` and
`claude-work` (the same Claude config, but in `~/.claude-work`).
By default `base`, `fish`, `zed` and `claude` are linked.
The `i3`, `mac` and `claude-work` groups are linked only when named, and the whole
i3 desktop is set up by `install-i3.sh` (section 1).

### macOS

```sh
./install-mac.sh -n --admin   # only print what it would do
./install-mac.sh --admin      # brew: fish, tmux, fzf, Zed, AeroSpace + links + chsh
./install-mac.sh              # no admin rights: build from source
```

With `--admin` everything goes through Homebrew (installed if missing) and fish
becomes the login shell (`chsh`, asks for your password). Anything built from
source earlier is deleted: fish and tmux from `~/.local/bin`, `~/.local/src`, Rust
(`~/.rustup`, `~/.cargo`) and the `~/.zshrc` block that started fish (a
`~/.zshrc.bak-<date>` is made first). If the user isn't in the `admin` group,
`--admin` refuses to run.

Without `--admin`, tmux (with static libevent and utf8proc) and fish (via
rustup/cargo) are built from source into `~/.local/bin`, and the source code stays
in `~/.local/src`. This needs only the Xcode Command Line Tools
(`xcode-select --install`). Zed and AeroSpace are skipped then, and since there is
no `chsh`, the script appends a block to `~/.zshrc` that starts fish.

It links `fish`, `vim`, `tmux`, `zed`, `mac` (AeroSpace and Ghostty config) and
`claude-work`; anything else can be added as needed (`./install.sh base`).
Differences from Linux:

- Claude Code is set up only for the work account: skills, commands and
  `settings.json` are linked into `~/.claude-work`, and `~/.claude` is left alone.
  It's started with `ccw` (alias in `config.fish`), and in Zed as the "Claude Work" agent.
- fish is linked file by file (`config.fish`, `functions/`, `fish_plugins`), without
  `conf.d/` and `fish_variables`, which are tied to the Linux machine.
- `config.fish` and `.tmux.conf` are written to work on both systems (`$HOME` instead
  of `/home/nebojsa`, `pbcopy` instead of `xclip`, pyenv/tmux/Homebrew only if present).
- Vim, Zed (vim mode) and tmux use the system clipboard, so copy/paste works
  between them and other apps; in tmux `prefix + ]` pastes the system clipboard.
- `.gitconfig` (the `base` group) needs `git-delta` and a GPG key for signing
  commits, so on Mac link it only once both exist.
- AeroSpace (`mac/.aerospace.toml`) is a window manager with shortcuts ported from
  the i3 config; after installing, start it once and give it Accessibility.
- `mac/.yabairc` and `mac/.skhdrc` are neither installed nor linked: yabai needs
  SIP disabled to work fully, which isn't an option on a work Mac, so AeroSpace
  replaces it. `mac/sublime/` isn't linked either.
- Karabiner-Elements (`mac/karabiner/karabiner.json`) is deliberately **not**
  installed or linked for now: the plan is to get used to the native macOS ⌘
  shortcuts first. The config is kept in case that doesn't work out; it swaps ⌘/⌥
  on the external keyboard, maps Ctrl+Shift+C/V/X to copy/paste/cut in terminals,
  and outside terminals maps Ctrl+letter to ⌘, Ctrl+arrows to word jumps and
  Home/End to line start/end. Installing it needs admin and approving its driver
  (system extension). Without it, the ⌘/⌥ swap for AeroSpace is done by hand in
  System Settings → Keyboard → Modifier Keys.

The script can be run repeatedly: a correct link is skipped (`ok`), and if
something else already exists at the target, it is first moved to
`<name>.bak-<date>` and only then linked. `install.sh` deletes nothing and doesn't
use `sudo` (deleting the source builds is done only by `install-mac.sh --admin`).

`--install-fish` is the only part that asks for a password: if fish isn't installed,
it installs it via `apt`/`dnf`/`pacman`/`brew`, links the fish config and finally
runs `chsh` (adding fish to `/etc/shells` first if needed). If fish is already
installed and already the login shell, it does nothing.

When a new file that needs linking is added to the repo, add one `link` line to
the right group in `install.sh` and a row to the table in section 3.

**For an AI agent:** on a new machine run `./install.sh -n`, show the output, then
`./install.sh`. Don't make links by hand and don't delete `.bak-*` files without asking.
Run `./install.sh --install-fish` and `./install-i3.sh` only when explicitly asked,
since they install packages and need `sudo`.

Files under `system/` in this repo are **not** symlinked (they live outside `$HOME`
and are owned by `root`); they are only reference snapshots of system files.
`i3.desktop` is installed by `install-i3.sh`, the Chrome wrapper is installed by
hand, see section 4.

## 3. What's where (map)

| In the repo | Symlinked at | What it does |
|---|---|---|
| `.config/i3/config` | `~/.config/i3/config` | main i3 config |
| `.config/i3/scripts/` | `~/.config/i3/scripts` | `layout-notify` (announces keyboard layout changes in dunst), `keyboard-layout.sh` (sets the layouts and restores them when the USB switch reconnects the keyboard) and `i3-confirm-power.sh` (shutdown/reboot confirmation) |
| `.config/fish/` | `~/.config/fish` | fish config, functions, `fish_plugins` (fisher) |
| `.config/rofi/config.rasi` | `~/.config/rofi/config.rasi` | rofi theme/layout |
| `.config/polybar/` | `~/.config/polybar/*` | polybar bar config + `launch.sh` + scripts (e.g. `eth-ip.sh`) |
| `.config/dunst/dunstrc` | `~/.config/dunst/dunstrc` | notification look/timeouts |
| `.config/picom/picom.conf` | `~/.config/picom/picom.conf` | compositor (transparency, shadows) |
| `.config/zed/settings.json`, `keymap.json` | `~/.config/zed/*` | Zed settings and shortcuts; the "Claude Work" agent is started through `sh -c` so that `$HOME/.claude-work` works on every machine |
| `mac/.aerospace.toml` | `~/.aerospace.toml` | AeroSpace window manager, shortcuts ported from i3 (Mac) |
| `mac/ghostty/config` | `~/.config/ghostty/config` | Ghostty terminal, same colors as the GNOME Terminal profile (Mac) |
| `.screenlayout/*.sh` | `~/.screenlayout/*.sh` | arandr layout scripts (see section 5) |
| `.local/bin/i3-x11` | `~/.local/bin/i3-x11` | wrapper that forces an X11 session before `exec i3` |
| `.local/share/xsessions/i3.desktop` | `~/.local/share/xsessions/i3.desktop` | user-level xsession entry (see section 4; GDM does *not* read this one before login, it's kept in case of another display manager) |
| `system/usr/share/xsessions/i3.desktop` | *(copy by hand, sudo)* | the **actual** xsession entry GDM uses |
| `system/usr/local/bin/google-chrome` | *(copy by hand, sudo)* | wrapper with GPU/WebRTC flags for Chrome |
| `.conkyrc`, `.conky/`, `.vimrc`, `.Xresources`, `.tmux.conf`, `.tmate.conf`, `.gitconfig` | `~/...` | standard dotfiles |
| `.claude/skills/` | `~/.claude/skills` | global Claude Code skills (the whole directory) |
| `.claude/commands/` | `~/.claude/commands` | global slash commands |
| `.claude/settings.json` | `~/.claude/settings.json` | Claude Code settings (permissions, theme) |

## 4. Chrome / X11 fix

Chrome misbehaved (black screen / bad rendering) under i3 because ozone platform
auto-detection sometimes picked the wrong session, and especially because of the
GPU video-decode/WebRTC path on this GPU/driver combination. The fix has two parts:

1. **Forcing an X11 session**: `~/.local/bin/i3-x11` is a small wrapper:
   ```sh
   #!/bin/sh
   export XDG_SESSION_TYPE=x11
   exec /usr/bin/i3 "$@"
   ```
   The system xsession entry `/usr/share/xsessions/i3.desktop` (GDM reads this one,
   **not** `~/.local/share/xsessions`) is changed to call this wrapper instead of
   `i3` directly:
   ```
   Exec=/home/nebojsa/.local/bin/i3-x11
   ```
   The original (before the change) comes with the package and calls `i3`; it is
   reinstalled on every i3 package update, so **this step has to be repeated on
   every new system** (and after i3 package updates). `./install-i3.sh` does it,
   writing the current user's `$HOME` into `Exec` instead of `/home/nebojsa`.

2. **GPU/WebRTC flags for Chrome**: `/usr/local/bin/google-chrome` is a custom
   wrapper that is called instead of `/usr/bin/google-chrome-stable`:
   ```sh
   #!/bin/bash
   /usr/bin/google-chrome-stable \
     --disable-features=WebRtcUseGpuMemoryBuffer \
     --disable-accelerated-video-decode \
     "$@"
   ```
   Installing on a new system:
   ```sh
   sudo install -m 755 ~/tools/dotenvs/system/usr/local/bin/google-chrome \
       /usr/local/bin/google-chrome
   ```
   `/usr/local/bin` comes before `/usr/bin` in `$PATH`, so this wrapper takes
   priority over the real binary.

## 5. arandr / monitor layout

`.screenlayout/` holds scripts generated by **arandr** (Preferences →
`arandr`, then Layout → Save As...) for different monitor setups:

- `monitors.sh`: laptop + 3 monitors over DP-3-x (docking station #1)
- `monitors-dp2.sh`: the same, but the docking station shows up as DP-2-x
- `monitors-hr.sh`: laptop + 1 external monitor (home office)
- `auto-monitors.sh`: automatically picks one of the above based on what
  `xrandr` reports as `connected`; it's called from the i3 config at startup
  (`exec --no-startup-id ~/.screenlayout/auto-monitors.sh`)

When the monitor setup changes (new docking station, new monitor), run
`arandr`, arrange the screens, save it as a new `.sh` script in `~/.screenlayout/`
(which is a symlink into the repo), and add a branch to `auto-monitors.sh` following
the same pattern (`xrandr | grep -q "^<output> connected"`).

## 6. Layout indicator (RS/US keyboard)

At startup the i3 config cycles through the layouts in a loop so the `xkb` state
gets reported and the status bar refreshes (`setxkbmap -layout us,rs(latin),rs
-option grp:alt_shift_toggle`), and `.config/i3/scripts/layout-notify` is a binary
program (source in `layout-notify.c`, uses only `libX11`/XKBlib, needs the
`libx11-dev` package; build it with `gcc -o layout-notify layout-notify.c -lX11`
if the binary is missing on a new system) that sends a dunst notification when the
layout changes.

## 7. Claude Code

The repo holds only what carries over from machine to machine:

- `.claude/skills/`: my global skills; the whole directory is a symlink, so
  every new skill created in `~/.claude/skills` is immediately in the repo, ready
  to commit. Claude also writes `synced/` into the same directory (skills it syncs
  from the account itself); that subdirectory is in `.gitignore`.
- `.claude/commands/`: global slash commands; the whole directory is a symlink,
  so anything added to `~/.claude/commands` ends up in the repo.
- `.claude/settings.json`: settings (permissions allow/deny, theme).

Deliberately **not** in the repo:

- `~/.claude.json`: contains account data (`oauthAccount`, `userID`,
  `machineID`), project history with local paths, and cache; Claude rewrites it
  constantly, so a symlink would get replaced by a plain file anyway.
- `~/.claude/.credentials.json`: the login token.
- `~/.claude/settings.local.json`, `projects/`, `history.jsonl`, `sessions/` and
  the rest: state tied to this machine.

On a new machine, do the `claude` login first, then the symlinks from section 2.
