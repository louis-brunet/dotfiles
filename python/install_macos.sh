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
    # FIXME:
    # exception
    # ssl.SSLCertVerificationError: [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:1000)
    curl -sSL https://install.python-poetry.org | python3 -
}
