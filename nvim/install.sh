#!/usr/bin/env bash

set -e

DOTFILES_ALWAYS_UPDATE_NVIM=1

# Define ANSI escape codes for red color and reset
ANSI_RED='\033[0;31m'
ANSI_NC='\033[0m' # No Color

SCRIPT_PATH=$(readlink -f "$0")

# NOTE: $HOME/bin should be in PATH
NVIM_EXECUTABLE_PATH="$HOME/bin/nvim"

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

build_jq_filter() {
    local asset_name="$1"
    if [[ -z "$asset_name" ]]; then
        fail "[build_jq_filter] missing asset name parameter"
    fi
    echo '.assets[] | select(.name == "'"$asset_name"'") | {download_url: .browser_download_url, sha_digest: .digest}'
}

# download latest stable appimage, save it as $HOME/bin/nvim with execution permissions
download_nvim_and_verify_checksum() {
    local asset_jq_filter
    if ! asset_jq_filter="$(build_jq_filter "nvim-linux-x86_64.appimage")"; then
        fail "build jq filter"
    fi
    # API documentation: https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#get-a-release
    local latest_release_url="https://api.github.com/repos/neovim/neovim/releases/tags/stable"
    echo "🌐 getting latest release info from $latest_release_url"
    local asset_info_json
    if ! asset_info_json=$(curl --location \
        --header "Accept: application/vnd.github.v3+json" \
        --header "X-GitHub-Api-Version: 2022-11-28" \
        "$latest_release_url" |
        jq -r "$asset_jq_filter"); then
        fail "[download_nvim_and_verify_checksum] could not find asset download url and SHA digest"
    fi
    local asset_download_url
    asset_download_url="$(jq --raw-output '.download_url' <<<"$asset_info_json")"
    local asset_sha
    asset_sha="$(jq --raw-output '.sha_digest' <<<"$asset_info_json")"

    if [[ -z "$asset_download_url" ]]; then
        fail "could not find asset download URL"
    fi
    print_success "found asset download URL: $asset_download_url"

    if [[ -z "$asset_sha" ]]; then
        fail "could not find asset SHA digest"
    fi
    print_success "found asset SHA digest: $asset_sha"

    nvim_download_path="${NVIM_EXECUTABLE_PATH}.downloading"
    nvim_download_url="$asset_download_url"
    nvim_sha_digest="$asset_sha"

    # Download the file
    echo "🌐 pulling latest stable nvim appimage from $nvim_download_url"
    curl --output "$nvim_download_path" --location "$nvim_download_url"

    # Extract just the hash value (remove "sha256:" prefix)
    expected_hash="${nvim_sha_digest#sha256:}"

    # Calculate the SHA256 of the downloaded file
    actual_hash=$(sha256sum "$nvim_download_path" | cut -d' ' -f1)

    # Verify the hashes match
    if [ "$expected_hash" = "$actual_hash" ]; then
        print_success "SHA256 verification successful (expected: $expected_hash, actual: $actual_hash)"
    else
        fail "✗ SHA256 verification failed! (expected: $expected_hash, actual: $actual_hash)"
    fi

    # Install the downloaded file as the global "nvim" command
    mv "$nvim_download_path" "$NVIM_EXECUTABLE_PATH"

    # Make the AppImage executable
    chmod +x "$NVIM_EXECUTABLE_PATH"
}

# # NOTE: $HOME/bin should be in PATH
# nvim_path="$HOME/bin/nvim"
if [[ ! -x "$NVIM_EXECUTABLE_PATH" ]] || [[ -n "$DOTFILES_ALWAYS_UPDATE_NVIM" ]]; then
    download_nvim_and_verify_checksum
fi

# sudo snap install nvim --classic

if ! nvim --version; then
    sudo apt install libfuse2 -y
    print_success "installed libfuse2 to run AppImages"
fi
print_success "installed nvim"
