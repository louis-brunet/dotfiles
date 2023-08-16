# add all functions defined in functions/ to fpath 
fpath=($DOTFILES/functions $fpath)

# autoload these functions
autoload -U $DOTFILES/functions/*(:t) # The (:t) modifier grabs the basename

