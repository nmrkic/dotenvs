#!/usr/bin/env bash
# Usage: i3-confirm-power.sh poweroff|reboot|exit

action="$1"

case "$action" in
    poweroff)
        prompt="Ugasi sistem?"
        key="P"
        kbkey="P"
        cmd="systemctl poweroff"
        ;;
    reboot)
        prompt="Restartuj sistem?"
        key="B"
        kbkey="B"
        cmd="systemctl reboot"
        ;;
    exit)
        prompt="Izlaz iz i3?"
        key="E"
        kbkey="E"
        cmd="i3-msg exit"
        ;;
    *)
        exit 1
        ;;
esac

out=$(printf 'Da\nNe\n' | rofi -dmenu -p "$prompt" -mesg "Pritisni <b>$key</b> za brzu potvrdu" -markup-rows -kb-custom-1 "$kbkey" -kb-custom-2 "Super+$kbkey")
code=$?

if [ "$code" = 10 ] || [ "$code" = 11 ] || [ "$out" = "Da" ]; then
    $cmd
fi
