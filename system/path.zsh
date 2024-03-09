local system_bin="$HOME/bin:$DOTFILES/bin"

case ":${PATH}:" in
    *:"$system_bin":*)
        ;;
    *)
        export PATH="$system_bin:$PATH"
        ;;
esac
# export PATH="$HOME/bin:$DOTFILES/bin:$PATH"

export XDG_CONFIG_HOME="$HOME/.config"
