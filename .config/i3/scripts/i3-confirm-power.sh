#!/usr/bin/env bash
# Usage: i3-confirm-power.sh poweroff|reboot

action="$1"

case "$action" in
    poweroff)
        prompt="Ugasi sistem?"
        key="p"
        ;;
    reboot)
        prompt="Restartuj sistem?"
        key="b"
        ;;
    *)
        exit 1
        ;;
esac

out=$(printf 'Da\nNe\n' | rofi -dmenu -p "$prompt" -mesg "Pritisni <b>$key</b> za brzu potvrdu" -markup-rows -kb-custom-1 "$key")
code=$?

if [ "$code" = 10 ] || [ "$out" = "Da" ]; then
    systemctl "$action"
fi
