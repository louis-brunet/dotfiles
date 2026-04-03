local hist_size=1000000

export HISTFILE=~/.histfile
export HISTSIZE=$hist_size
export SAVEHIST=$hist_size

# Ignore duplicates in history
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS

