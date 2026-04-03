local system_bin="$HOME/bin:${DOTFILES:-$HOME/code/dotfiles}/bin:$HOME/.local/bin"

case ":${PATH}:" in
    *:"$system_bin":*)
        ;;
    *)
        export PATH="$system_bin:$PATH"
        ;;
esac
# export PATH="$HOME/bin:$DOTFILES/bin:$PATH"

# https://wiki.archlinux.org/title/XDG_Base_Directory
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# Proposed standard to disable telemetry in TUI apps
# https://consoledonottrack.com/
export DO_NOT_TRACK=1
