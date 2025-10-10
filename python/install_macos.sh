#!/usr/bin/env bash

set -e

# Install uv using Homebrew.
# uv is a fast, all-in-one Python package and project manager.
# It replaces pyenv, poetry, pip, and virtualenv.

which uv || {
    echo "Installing uv with Homebrew..."
    # 'brew install uv' installs the latest stable release
    brew install uv
    echo "uv installed."
}


# PYENV_ROOT="$HOME/.pyenv"
# PYENV_PLUGINS="$PYENV_ROOT/plugins"
# PYENV_PLUGIN_VIRTUALENV="$PYENV_PLUGINS/pyenv-virtualenv"
#
# brew install pyenv
#
# [[ -d "$PYENV_PLUGIN_VIRTUALENV" ]] || {
#     git clone https://github.com/pyenv/pyenv-virtualenv.git "$PYENV_PLUGIN_VIRTUALENV"
# }
#
# which poetry || {
#     # https://python-poetry.org/docs/#installing-with-the-official-installer
#     curl -sSL https://install.python-poetry.org | python3 -
# }

# # needed to build wheels from source with pip
# brew install cmake
