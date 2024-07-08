#!/usr/bin/env bash

set -e

PYENV_ROOT="$HOME/.pyenv"

[[ -d "$PYENV_ROOT" ]] || {
    sudo apt update
    sudo apt install -y make build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
    libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl \
    git

    git clone https://github.com/pyenv/pyenv.git "$PYENV_ROOT"
}
