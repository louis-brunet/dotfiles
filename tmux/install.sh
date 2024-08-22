#!/bin/bash

set -e

sudo apt install tmux -y

tmux -V

if ! which fzf
then
    # sudo apt install fzf -y
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --no-update-rc --xdg
fi
fzf --version

echo "✅ installed tmux (& fzf for tmux-sessionizer)"

