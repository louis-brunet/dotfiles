#!/usr/bin/env bash

set -e

PYENV_ROOT="$HOME/.pyenv"
PYENV_PLUGINS="$PYENV_ROOT/plugins"
PYENV_PLUGIN_VIRTUALENV="$PYENV_PLUGINS/pyenv-virtualenv"

brew install pyenv

[[ -d "$PYENV_PLUGIN_VIRTUALENV" ]] || {
    git clone https://github.com/pyenv/pyenv-virtualenv.git "$PYENV_PLUGIN_VIRTUALENV"
}

which poetry || {
    curl -sSL https://install.python-poetry.org | python3 -
}

# # needed to build wheels from source with pip
# brew install cmake
