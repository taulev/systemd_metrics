#!/bin/bash
# Main command
# sudo -u telegraf systemctl list-units telegraf* --all --plain --type=service --no-legend

patterns=(
"telegraf*"
"influx*"
"test"
)

echo ${patterns[@]}
