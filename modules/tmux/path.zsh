[ -f "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.zsh ] && source "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.zsh

export TMUX_SESSIONIZER_DIRS="$PROJECTS"

# possibly defined in ~/.localrc
if [[ -n "$LOCAL_TMUX_SESSIONIZER_DIRS" ]]; then
    export TMUX_SESSIONIZER_DIRS="$LOCAL_TMUX_SESSIONIZER_DIRS:$TMUX_SESSIONIZER_DIRS"
fi

# vim:ft=sh:
