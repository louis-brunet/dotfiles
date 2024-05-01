#!/bin/bash

set -e
# echo "⚠️  TODO: uncomment nvim install script (commented bc docker ubuntu doesn't support snap)"

sudo apt install make

# $HOME/bin should be in PATH
nvim_path="$HOME/bin/nvim"
if [[ ! -x "$nvim_path" ]]; then
    # download latest stable appimage, save it as $HOME/bin/nvim with execution permissions
    echo "🌐 pulling latest stable nvim appimage"
    mkdir -p "$(dirname "$nvim_path")"
    curl -o "$nvim_path" -L https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
    chmod u+x "$nvim_path"
fi

# sudo snap install nvim --classic

if ! nvim --version; then
    sudo apt install libfuse2 -y
    echo "✅ installed libfuse2 to run AppImages"
else
    echo "✅ installed nvim"
fi

sudo apt install ripgrep
rg --version
echo "✅ installed ripgrep for Telescope"

