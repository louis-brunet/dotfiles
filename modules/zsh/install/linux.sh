#!/bin/bash

set -e

# install zsh
sudo apt install zsh -y
echo "✅ installed zsh"
zsh --version

# set zsh as default shell
sudo chsh -s "$(which zsh)" "$(whoami)"
echo "✅ set zsh as default shell"

if [ -n "$ZSH" ] && [ -d "$ZSH" ]
then
    echo "✅ \$ZSH variable is set ($ZSH). Considering oh-my-zsh as installed."
else
    # install oh-my-zsh
    omz_install_script=install_omz.sh
    sudo apt install wget git -y
    wget -O "$omz_install_script" https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
    sh "$omz_install_script" --keep-zshrc
    rm "$omz_install_script"
    echo "✅ installed oh-my-zsh"
fi
zsh_custom=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

# install the powerlevel10k theme for zsh
P10K_DIR="$zsh_custom"/themes/powerlevel10k
if [ ! -d "$P10K_DIR" ]
then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    echo "✅ downloaded powerlevel10k theme"
fi

ZSH_AUTOSUGGESTIONS_DIR="$zsh_custom/plugins/zsh-autosuggestions"
if [ ! -d "$ZSH_AUTOSUGGESTIONS_DIR" ]
then
    echo "could not find dir ${ZSH_AUTOSUGGESTIONS_DIR}, downloading"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR"
    echo "✅ downloaded zsh-autosuggestions plugin"
fi

ZSH_YARN_SUGGESTIONS_DIR="$zsh_custom/plugins/zsh-yarn-completions"
if [ ! -d "$ZSH_YARN_SUGGESTIONS_DIR" ]
then
    echo "could not find dir ${ZSH_YARN_SUGGESTIONS_DIR}, downloading"
    git clone https://github.com/chrisands/zsh-yarn-completions "$ZSH_YARN_SUGGESTIONS_DIR"
    echo "✅ downloaded zsh-yarn-completions"
fi

