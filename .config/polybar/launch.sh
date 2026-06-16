#!/bin/sh
killall -q polybar

PRIMARY=$(polybar --list-monitors | grep primary | cut -d":" -f1)

for monitor in $(polybar --list-monitors | cut -d":" -f1); do
    if [ "$monitor" = "$PRIMARY" ]; then
        MONITOR=$monitor polybar main &
    else
        MONITOR=$monitor polybar secondary &
    fi
done
