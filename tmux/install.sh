#!/bin/bash

set -e 

sudo apt install tmux fzf -y
fzf --version
tmux --version

echo "✅ installed tmux (& fzf for tmux-sessionizer)"

