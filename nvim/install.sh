#!/usr/bin/env bash

set -e

DOTFILES_ALWAYS_UPDATE_NVIM=1

# Define ANSI escape codes for red color and reset
ANSI_RED='\033[0;31m'
ANSI_NC='\033[0m' # No Color

SCRIPT_PATH=$(readlink -f "$0")

print_error() {
    # Check if stderr is a TTY (interactive terminal) to enable color output
    if [ -t 2 ]; then
        echo -e "$SCRIPT_PATH: ${ANSI_RED}[ERROR]${ANSI_NC} $*" >&2
    else
        echo "$SCRIPT_PATH: [ERROR] $*" >&2
    fi
}

print_success() {
    echo "$SCRIPT_PATH: ✅ $*"
}

fail() {
    local message="$*"
    if [[ -n "$message" ]]; then
        print_error "$message"
    fi
    exit 1
}

get_dependencies() {
    sudo apt install make jq

    sudo apt install -y ripgrep
    rg --version
    print_success "installed ripgrep for Telescope"

    if ! which tree-sitter >/dev/null; then
        if which npm >/dev/null; then
            npm install -g tree-sitter-cli
            print_success "installed tree-sitter CLI to install languages (latex) from grammar"
        fi
    fi

    # sudo apt install -y liblua5.1-0-dev
    # echo "✅ installed Lua for luarocks.nvim (rest.nvim)"

    # NOTE: install missing python3-venv for Mason to install certain packages,
    # like ruff. Should only be needed for Ubuntu/Debian
    # WARN: assumes that WSL is running Ubuntu/Debian
    if python3 -mplatform | grep -qiE 'Ubuntu|Debian|WSL'; then
        sudo apt install -y python3-venv
        print_success "installed python3-venv for certain Mason installs"
    fi
}

download_nvim_and_verify_checksum() {
    # download latest stable appimage, save it as $HOME/bin/nvim with execution permissions
    echo "🌐 pulling latest stable nvim appimage"

    nvim_release_url="https://github.com/neovim/neovim/releases/download/stable"
    nvim_download_path="${nvim_path}.downloading"
    nvim_download_url="${nvim_release_url}/nvim-linux-x86_64.appimage"
    nvim_shasum_txt_download_path="${nvim_path}.shasum.txt"
    nvim_shasum_txt_download_url="${nvim_release_url}/shasum.txt"

    mkdir -p "$(dirname "$nvim_path")"

    if ! curl -o "$nvim_download_path" -L "$nvim_download_url"; then
        fail "could not download $nvim_download_url to $nvim_download_path"
    fi
    if ! curl -o "$nvim_shasum_txt_download_path" -L "$nvim_shasum_txt_download_url"; then
        fail "could not download $nvim_shasum_txt_download_url to $nvim_shasum_txt_download_path"
    fi

    nvim_download_path_sha256=$(sha256sum "$nvim_download_path" | awk '{print $1}')
    grep --quiet "$nvim_download_path_sha256" "$nvim_shasum_txt_download_path" || {
        rm "$nvim_shasum_txt_download_path"
        fail "invalid checksum for ${nvim_download_path}: could not find checksum '$nvim_download_path_sha256' in file '$nvim_shasum_txt_download_path'"
    }
    print_success "Validated checksum for $nvim_download_path"
    rm "$nvim_shasum_txt_download_path"

    mv "$nvim_download_path" "$nvim_path"
    chmod u+x "$nvim_path"
}

# NOTE: $HOME/bin should be in PATH
nvim_path="$HOME/bin/nvim"
if [[ ! -x "$nvim_path" ]] || [[ -n "$DOTFILES_ALWAYS_UPDATE_NVIM" ]]; then
    download_nvim_and_verify_checksum
fi

# sudo snap install nvim --classic

if ! nvim --version; then
    sudo apt install libfuse2 -y
    print_success "installed libfuse2 to run AppImages"
fi
print_success "installed nvim"
