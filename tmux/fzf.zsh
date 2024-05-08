local fzf_config_file="${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.zsh
local fzf_git_config_file="$DOTFILES"/tmux/fzf-git.sh

[ -f "$fzf_config_file" ] && source "$fzf_config_file"

# https://github.com/junegunn/fzf-git.sh/?tab=readme-ov-file#list-of-bindings
[ -f "$fzf_git_config_file" ] && source "$fzf_git_config_file"

local fzf_default_opts=(
    --cycle
    --info inline-right
    --preview-window "right,50%,border-left,<70(up,30%,border-bottom)"
    --color "dark,pointer:red,prompt:bright-blue,bg+:bright-black"
)
export FZF_DEFAULT_OPTS="${fzf_default_opts[@]}"
