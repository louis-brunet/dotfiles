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

# if [ "$LOCAL_ENV" = "neoxia" ]; then
#     # NOTE: will not work when not on macOS
#     if which security >/dev/null; then
#         combined_netskope_cert="/Library/Application Support/Netskope/STAgent/data/nscacert_combined.pem"
#         if [ ! -f "$combined_netskope_cert" ]; then
#             echo "missing file '$combined_netskope_cert', generating"
#             tmp_file="$(mktemp)"
#
#             security find-certificate -a -p /System/Library/Keychains/SystemRootCertificates.keychain /Library/Keychains/System.keychain >"$tmp_file"
#             sudo cp "$tmp_file" "$combined_netskope_cert"
#         fi
#         export REQUESTS_CA_BUNDLE="$combined_netskope_cert"
#     fi
#     # export REQUESTS_CA_BUNDLE="/Library/Application Support/Netskope/STAgent/data/nscacert.pem"
# fi
