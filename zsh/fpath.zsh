#add each topic folder to fpath so that they can add functions and completion scripts
for topic_folder ($DOTFILES/*) [ -d $topic_folder ] && fpath=($topic_folder $fpath);

