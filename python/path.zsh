export PYENV_ROOT="$HOME/.pyenv"
export PYENV_BIN="$PYENV_ROOT/bin"
[[ -d "$PYENV_BIN" ]] && export PATH="$PYENV_ROOT/bin:$PATH"

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
