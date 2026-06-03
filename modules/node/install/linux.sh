#!/usr/bin/env bash
# Install node and npm with mise

set -e

echo "Installing Node.js LTS..."

# Install the latest LTS version of Node and set it globally
mise use --global node@lts

# Reshim to ensure binaries are mapped properly
mise reshim

echo "node $(mise exec -- node --version)"
echo "npm $(mise exec -- npm --version)"
echo "✅ installed node LTS and npm via mise"
echo "👉 Please run 'exec zsh' or restart your terminal to activate."
if ! which nvm >/dev/null; then
    XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config} PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash'

    # load nvm for current terminal session
    # this is also done by the oh-my-zsh plugin "nvm"
    export NVM_DIR="$(printf %s "${XDG_CONFIG_HOME:-$HOME/.config}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" # This loads nvm

    nvm --version
    echo "✅ installed nvm (run exec zsh)"
fi
