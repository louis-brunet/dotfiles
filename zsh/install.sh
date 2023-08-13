#!/bin/bash 

set -e

# install zsh
apt update && apt install zsh -y
echo "✅ installed zsh"
zsh --version
# if [ ! $(which zsh) ]
# then
# fi

# set zsh as default shell
chsh -s $(which zsh)
echo "✅ set zsh as default shell"
# if [ $(basename -- "$SHELL") != "zsh" ]
# then
# fi

if [ -n "$ZSH" ] && [ -d "$ZSH" ]
then
    echo "✅ \$ZSH variable is set ($ZSH). Considering oh-my-zsh as installed."
else
    # install oh-my-zsh
    # apt install curl git -y
    apt install wget git -y
    wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
    sh install.sh --keep-zshrc
    # sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
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
if [ ! -d "$ZSH_AUTOSUGGESTION_DIR" ]
then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_DIR"
    echo "✅ downloaded zsh-autosuggestions plugin"
fi

# else
#     echo "❌ \$ZSH_CUSTOM is not a directory ! ('$ZSH_CUSTOM')"
# fi
#
