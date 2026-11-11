source <(fzf --zsh)

# local fzf_config_file="${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.zsh
#
# [ -f "$fzf_config_file" ] && source "$fzf_config_file"

if [ -d "$DOTFILES" ]; then
    local fzf_git_config_file="$DOTFILES"/tmux/fzf-git.sh
    # https://github.com/junegunn/fzf-git.sh/?tab=readme-ov-file#list-of-bindings
    [ -f "$fzf_git_config_file" ] && source "$fzf_git_config_file"
fi

local fzf_default_opts=(
    --cycle
    --info inline-right
    --layout reverse
    --preview-window "right,50%,border-left,<70(up,30%,border-bottom)"
    --color "dark,pointer:red,prompt:bright-blue,bg+:bright-black"
)
export FZF_DEFAULT_OPTS="${fzf_default_opts[@]}"

local fzf_ctrl_r_opts=(
    --no-sort
    # --preview "echo {}"
    # --preview-window "down:3:hidden:wrap"
    # --bind "?:toggle-preview"
)
export FZF_CTRL_R_OPTS="${fzf_ctrl_r_opts[@]}"


fzf-custom-history-widget() {
	local selected
	setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases noglob nobash_rematch 2> /dev/null
    selected="$(fc -rl 1 | awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, "", cmd); if (!seen[cmd]++) print $0 }' |
  FZF_DEFAULT_OPTS=$(__fzf_defaults "" "-n2..,.. --scheme=history --bind=ctrl-r:toggle-sort --wrap-sign '\t↳ ' --highlight-line ${FZF_CTRL_R_OPTS-} --query=${(qqq)LBUFFER} +m") \
  FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd))"
	local ret=$?
	if [ -n "$selected" ]
	then
		if [[ $(awk '{print $1; exit}' <<< "$selected") =~ ^[1-9][0-9]* ]]
		then
			zle vi-fetch-history -n $MATCH
		else
			LBUFFER="$selected"
		fi
	fi
	zle reset-prompt
	return $ret
}
zle -N fzf-custom-history-widget

# bindkey "^R" "fzf"
bindkey -M viins '^R' fzf-custom-history-widget
bindkey -M vicmd '^R' fzf-custom-history-widget
# bindkey -M viins '^R' "sh -c 'history | fzf --tac --no-sort^M'"
