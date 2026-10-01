#!/usr/bin/env bash
# Usage: toggle-notifications.sh

if [ "$(dunstctl is-paused)" = "true" ]; then
    dunstctl set-paused false
    notify-send -u critical -t 1500 "Notifications" "Resumed"
else
    notify-send -u critical -t 1500 "Notifications" "Paused"
    sleep 2.5
    dunstctl set-paused true
fi
