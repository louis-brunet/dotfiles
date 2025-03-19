#!/usr/bin/env bash

set -e

DOTFILES_ALWAYS_UPDATE_NVIM=1

sudo apt install make

# NOTE: $HOME/bin should be in PATH
nvim_path="$HOME/bin/nvim"
if [[ ! -x "$nvim_path" ]] || [[ -n "$DOTFILES_ALWAYS_UPDATE_NVIM" ]]; then
    # download latest stable appimage, save it as $HOME/bin/nvim with execution permissions
    echo "🌐 pulling latest stable nvim appimage"

    nvim_download_path="${nvim_path}.downloading"
    nvim_download_url="https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.appimage"
    nvim_sha_download_path="${nvim_path}.sha256sum"
    nvim_sha_download_url="${nvim_download_url}.sha256sum"

    mkdir -p "$(dirname "$nvim_path")"

    curl -o "$nvim_download_path" -L "$nvim_download_url"
    curl -o "${nvim_sha_download_path}" -L "$nvim_sha_download_url"

    sha256sum "$nvim_download_path" | grep "$(cat "$nvim_sha_download_path" | cut -f 1 -d ' ')" || {
        echo "invalid checksum for ${nvim_download_path}"
        exit 1
    }
    echo 'Validated checksum'

    mv "$nvim_download_path" "$nvim_path"
    chmod u+x "$nvim_path"
fi

# sudo snap install nvim --classic

if ! nvim --version; then
    sudo apt install libfuse2 -y
    echo "✅ installed libfuse2 to run AppImages"
fi
echo "✅ installed nvim"

sudo apt install -y ripgrep
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
if python3 -mplatform | grep -qiE 'Ubuntu|Debian|WSL'; then
    sudo apt install -y python3-venv
fi
