#!/bin/bash

set -e

sudo apt install tmux -y
tmux -V

if ! which fzf
then
    sudo apt install fzf -y
fi
fzf --version

echo "✅ installed tmux (& fzf for tmux-sessionizer)"

