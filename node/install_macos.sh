# install node and npm with nvm
set -e 

if ! which nvm >/dev/null; then
    XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config} PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash'

    # load nvm for current terminal session
    # this is also done by the oh-my-zsh plugin "nvm"
    export NVM_DIR="$(printf %s "${XDG_CONFIG_HOME:-$HOME/.config}/nvm")"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" # This loads nvm
    
    nvm --version
    echo "✅ installed nvm (run exec zsh)"
fi

if ! which node >/dev/null; then
    nvm install --lts
    nvm use --lts

    echo "node $(node --version)"
    echo "npm $(npm --version)"
    echo "✅ installed node LTS and npm"
fi

