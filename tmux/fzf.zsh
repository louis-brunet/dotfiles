[ -f "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.zsh ] && source "${XDG_CONFIG_HOME:-$HOME/.config}"/fzf/fzf.zsh

export FZF_DEFAULT_OPTS='--border --cycle --color "dark,pointer:red,prompt:bright-blue,bg+:bright-black"'
