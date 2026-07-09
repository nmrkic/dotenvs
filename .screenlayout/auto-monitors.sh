#!/bin/sh

# Check which outputs are connected via xrandr
if xrandr | grep -q "^DP-3-1 connected"; then
    ~/.screenlayout/monitors.sh
elif xrandr | grep -q "^DP-2-1 connected"; then
    ~/.screenlayout/monitors-dp2.sh
elif xrandr | grep -q "^DP-2 connected"; then
    ~/.screenlayout/monitors-hr.sh
else
    # Only laptop screen
    xrandr --output eDP-1 --auto --primary
fi
