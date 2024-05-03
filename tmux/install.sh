#!/bin/bash

set -e

sudo apt install tmux fzf -y
fzf --version
tmux -V

echo "✅ installed tmux (& fzf for tmux-sessionizer)"

