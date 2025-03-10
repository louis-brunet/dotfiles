#!/bin/bash

set -e

brew install tmux
tmux -V

brew install fzf

# if ! which fzf
# then
#     # sudo apt install fzf -y
#     (cd ~ && rm -r .fzf)
#     git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
#     ~/.fzf/install --no-update-rc --xdg
# fi
# fzf --version

echo "✅ installed tmux (& fzf for tmux-sessionizer)"

