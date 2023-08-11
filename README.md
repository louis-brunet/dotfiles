# Configuration

## `symlinks.conf`, `<topic>/symlinks.conf`

This file configures the symlinks to add to the user's home directory. Each line
contains two relative paths, which can be files or directories, separated by
a colon (`:`).

The first path (source) is relative to this repository's root. The second path
(destination) is relative to the user's home directory. 

A symbolic link will be created at the destination by the bootstrap script. If
the destination already exists, the script asks the user whether to overwrite
it.

Example:
```
tmux/my_tmux.conf:.config/tmux/tmux.conf
nvim:.config/nvim
```

