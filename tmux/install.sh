#!/bin/bash

set -e

sudo apt install tmux -y

tmux -V

TPM_PLUGIN_PATH=~/.tmux/plugins/tpm
if [[ ! -e "$TPM_PLUGIN_PATH" ]]
then
    git clone https://github.com/tmux-plugins/tpm "$TPM_PLUGIN_PATH"
fi


if ! which fzf
then
    # sudo apt install fzf -y
    (cd ~ && rm -r .fzf) || true
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --no-update-rc --xdg
fi
# fzf --version

echo "✅ installed tmux (& fzf for tmux-sessionizer)"

