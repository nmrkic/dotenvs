#!/usr/bin/env bash
# Usage: i3-confirm-power.sh poweroff|reboot|exit

action="$1"

case "$action" in
    poweroff)
        prompt="Shut down?"
        key="P"
        kbkey="P"
        cmd="systemctl poweroff"
        ;;
    reboot)
        prompt="Reboot?"
        key="B"
        kbkey="B"
        cmd="systemctl reboot"
        ;;
    exit)
        prompt="Exit i3?"
        key="E"
        kbkey="E"
        cmd="i3-msg exit"
        ;;
    *)
        exit 1
        ;;
esac

out=$(printf 'Yes\nNo\n' | rofi -dmenu -p "$prompt" -mesg "Press <b>$key</b> to confirm" -markup-rows -kb-custom-1 "$kbkey" -kb-custom-2 "Super+$kbkey")
code=$?

if [ "$code" = 10 ] || [ "$code" = 11 ] || [ "$out" = "Yes" ]; then
    $cmd
fi
