#!/bin/bash 

set -e
# echo "⚠️  TODO: uncomment nvim install script (commented bc docker ubuntu doesn't support snap)"

# download latest stable appimage, save it as $HOME/bin/nvim with execution permissions
# $HOME/bin should be in PATH
echo "🌐 pulling latest stable nvim appimage"
nvim_path="$HOME/bin/nvim" 
mkdir -p "$(dirname "$nvim_path")"
curl -o "$nvim_path" -L https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
chmod u+x "$nvim_path"

# sudo snap install nvim --classic
nvim --version
echo "✅ installed nvim"

sudo apt install ripgrep
rg --version
echo "✅ installed ripgrep for Telescope"

