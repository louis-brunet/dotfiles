#!/bin/bash

set -e

sudo apt install make

# NOTE: $HOME/bin should be in PATH
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


if ! which tree-sitter >/dev/null
then
    if which npm >/dev/null
    then
        npm install -g tree-sitter-cli
        echo "✅ installed tree-sitter CLI to install languages (latex) from grammar"
    fi
fi

# sudo apt install -y liblua5.1-0-dev
# echo "✅ installed Lua for luarocks.nvim (rest.nvim)"

# NOTE: install missing python3-venv for Mason to install certain packages, 
# like ruff. Should only be needed for Ubuntu/Debian
# WARN: assumes that WSL is running Ubuntu/Debian
if python -mplatform | grep -qiE 'Ubuntu|Debian|WSL'; then
    sudo apt install python3-venv
fi
