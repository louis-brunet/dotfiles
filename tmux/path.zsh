_configure_fzf_path() {
    if ! which fzf 2>&1 >/dev/null; then
        local manual_fzf_install_path="$HOME/.fzf/bin"
        if [ -e "$manual_fzf_install_path/fzf" ] && [ ! "$PATH" == *"$manual_fzf_install_path"* ]; then
            export PATH="$manual_fzf_install_path:$PATH"
        fi
    fi
}

_configure_fzf_path

# if [ -d "$HOME/.fzf/bin" ]; then
#     ...
# fi

# if [[ ! "$PATH" == */Users/lbrunet/.fzf/bin* ]]; then
#   PATH="${PATH:+${PATH}:}/Users/lbrunet/.fzf/bin"
# fi

export TMUX_SESSIONIZER_DIRS="$PROJECTS"

# possibly defined in ~/.localrc
if [[ -n "$LOCAL_TMUX_SESSIONIZER_DIRS" ]]; then
    export TMUX_SESSIONIZER_DIRS="$LOCAL_TMUX_SESSIONIZER_DIRS:$TMUX_SESSIONIZER_DIRS"
fi

# vi:ft=sh:
