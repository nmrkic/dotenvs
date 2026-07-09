#!/bin/sh
# Find the first active wired (en*/eth*) interface and print its IP
for iface in $(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep -E '^(en|eth)'); do
    ip=$(ip -4 addr show "$iface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
    if [ -n "$ip" ]; then
        echo "eth $ip"
        exit 0
    fi
done
