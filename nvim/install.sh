#!/bin/bash 

set -e
# echo "⚠️  TODO: uncomment nvim install script (commented bc docker ubuntu doesn't support snap)"

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
nvim --version
if [ $? -ne 0 ]; then
    sudo apt install libfuse2 -y
    nvim --version
    if [ ! nvim --version ]; then
        echo "❗ could not run 'nvim --version', is FUSE installed ? (to run AppImages)"
    else 
        echo "✅ installed nvim"
    fi
else 
    echo "✅ installed nvim"
fi 

sudo apt install ripgrep
rg --version
echo "✅ installed ripgrep for Telescope"

