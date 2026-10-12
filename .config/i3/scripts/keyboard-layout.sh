#!/usr/bin/env bash
# Usage: keyboard-layout.sh [watch]
#
# Applies the keyboard layouts. With "watch", also reapplies them whenever an
# input device is attached: a hotplugged keyboard (USB switch) gets the system
# default from /etc/default/keyboard, which drops us and the Alt+Shift toggle.

apply() {
    setxkbmap -layout us,rs,rs -variant ,latin, -option '' -option grp:alt_shift_toggle
}

apply
[ "$1" = "watch" ] || exit 0

# One instance only
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/keyboard-layout-watch.lock"
flock -n 9 || exit 0

udevadm monitor --udev --subsystem-match=input 9>&- | while read -r line; do
    case "$line" in
        *" add "*)
            # A single plug fires many events; wait until they settle
            while read -r -t 1 line; do :; done
            apply
            ;;
    esac
done
