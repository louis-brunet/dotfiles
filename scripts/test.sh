# #!/bin/bash
#
# SYMLINK_DELIMITER=:
# cd "$(dirname "$0")/.."
# DOTFILES_ROOT=$(pwd -P)
# DESTINATION_ROOT=$HOME
#
# set -e 
#
# success () {
#   printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %s\n" "$1"
# }
#
# fail () {
#   printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %s\n" "$1"
#   echo ''
#   exit
# }
#
# info () {
#   printf "\r  [ \033[00;34m..\033[0m ] %s\n" "$1"
# }
#
# user () {
#   printf "\r  [ \033[0;33m??\033[0m ] %b\n" "$1"
# }
#
# link_file () {
#   local src=$1 dst=$2
#
#   local overwrite= backup= skip=
#   local action=
#
#   if [ -f "$dst" ] || [ -d "$dst" ] || [ -L "$dst" ]
#   then
#
#     if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]
#     then
#
#       local currentSrc="$(readlink $dst)"
#
#       if [ "$currentSrc" == "$src" ]
#       then
#
#         skip=true;
#
#       else
#
#         user "File already exists: $dst ($(basename "$src")), what do you want to do?\n\
# [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
#         read -n 1 action
#         echo "chose action: '$action'"
#
#         case "$action" in
#           o )
#             overwrite=true;;
#           O )
#             overwrite_all=true;;
#           b )
#             backup=true;;
#           B )
#             backup_all=true;;
#           s )
#             skip=true;;
#           S )
#             skip_all=true;;
#           * )
#             ;;
#         esac
#
#       fi
#
#     fi
#
#     overwrite=${overwrite:-$overwrite_all}
#     backup=${backup:-$backup_all}
#     skip=${skip:-$skip_all}
#
#     if [ "$overwrite" == "true" ]
#     then
#       rm -rf "$dst"
#       success "removed $dst"
#     fi
#
#     if [ "$backup" == "true" ]
#     then
#       mv "$dst" "${dst}.backup"
#       success "moved $dst to ${dst}.backup"
#     fi
#
#     if [ "$skip" == "true" ]
#     then
#       success "skipped $src"
#     fi
#   fi
#
#   if [ "$skip" != "true" ]  # "false" or empty
#   then
#     ln -s "$1" "$2"
#     success "linked $1 to $2"
#   fi
# }
#
# setup_symlinks () {
#   local filename="$1"
#   if [ ! -f "$filename" ] 
#   then 
#     fail "symlink config '$filename' is not a file"
#   fi
#   info "$filename"
#
#   local overwrite_all=false backup_all=false skip_all=false
#   # read from file descriptor 3 so the loop can prompt and read stdin
#   while read -ru 3 line 
#   do
#     if [ -z "$line" ]
#     then
#       continue
#     fi
#     local src=$DOTFILES_ROOT/${line%"$SYMLINK_DELIMITER"*}
#     local dst=$DESTINATION_ROOT/${line#*"$SYMLINK_DELIMITER"}
#
#     # echo "$line"
#     # echo "src = $src"
#     # echo "dst = $dst"
#
#     if [ ! -f "$src" ] && [ ! -d "$src" ] 
#     then
#       fail "$filename: '$src' is not a file or a directory"
#     fi
#     mkdir -p "$(dirname "$dst")"
#
#     link_file "$src" "$dst"
#   done 3< "$filename"
# }
#
# for symlinks_conf in $(find -H "$DOTFILES_ROOT" -maxdepth 2 -type f -name 'symlinks.conf' -not -path '*.git*')
# do
#   setup_symlinks "$symlinks_conf"
# done
#
