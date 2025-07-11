#!/usr/bin/env bash

set -e

# Terminate already running bar instances
# If all your bars have ipc enabled, you can use
polybar-msg cmd quit || echo "No running bars to terminate"
# Otherwise you can use the nuclear option:
# killall -q polybar

echo "---" | tee -a /tmp/polybar1.log
# Launch bar1
polybar --config="$HOME"/.config/polybar/config.ini bar1 2>&1 | tee -a /tmp/polybar1.log & disown
# polybar bar2 2>&1 | tee -a /tmp/polybar2.log & disown

echo "Bars launched..."

