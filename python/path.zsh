export PYENV_ROOT="$HOME/.pyenv"
export PYENV_BIN="$PYENV_ROOT/bin"
[[ -d "$PYENV_BIN" ]] && export PATH="$PYENV_ROOT/bin:$PATH"

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# On macOS, poetry config dir ignores XDG_CONFIG_HOME and defaults to
# "~/Library/Application Support/pypoetry".
#
# https://python-poetry.org/docs/configuration#config-directory
#
# https://github.com/python-poetry/poetry/issues/1239
# links to
# https://github.com/tox-dev/platformdirs/issues/4
export POETRY_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/pypoetry"
