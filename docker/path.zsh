if [[ -d "$HOME/.rd/bin" ]]
then
    # NOTE: Rancher Desktop GUI needs to manually be opened (and manual PATH modification selected) for $HOME/.rd/bin/ to be created
    export PATH="$HOME/.rd/bin:$PATH"
fi
