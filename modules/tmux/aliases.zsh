# color for tmux in GNOME terminal, display unicode
# alias tmux="TERM=xterm-256color tmux -u"
alias tmux="TERM=tmux-256color tmux -u"


### tmux-sessionizer

function _run_tmux_sessionizer() {
  if [[ $KEYMAP == "vicmd" ]]; then
    zle -K viins          # force switch to insert mode
  fi
  zle push-input
  BUFFER="tmux-sessionizer"
  zle accept-line
  zle pop-input
}

zle -N _run_tmux_sessionizer
bindkey -M vicmd "^F" _run_tmux_sessionizer   # bind in normal mode
bindkey -M viins "^F" _run_tmux_sessionizer   # bind in insert mode

