#!/bin/sh

# Check which outputs are connected via xrandr
if xrandr | grep -q "^DP-3-1 connected"; then
    # Lid closed: laptop screen off, all three external monitors on (DP-3-2 in the middle)
    if grep -q closed /proc/acpi/button/lid/*/state 2>/dev/null; then
        ~/.screenlayout/monitors-lid-closed.sh
    else
        ~/.screenlayout/monitors.sh
    fi
elif xrandr | grep -q "^DP-2-1 connected"; then
    ~/.screenlayout/monitors-dp2.sh
elif xrandr | grep -q "^DP-2 connected"; then
    ~/.screenlayout/monitors-hr.sh
else
    # Only laptop screen
    xrandr --output eDP-1 --auto --primary
fi
