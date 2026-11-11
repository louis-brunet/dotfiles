#!/usr/bin/env bash
# Shell module installation script for Linux
# Installs zsh, oh-my-zsh, and powerlevel10k theme

set -e

echo "Installing shell configuration (Linux)..."

# Install zsh if not present
if ! command -v zsh &> /dev/null; then
    sudo apt-get install -y zsh
    echo "✅ Installed zsh"
fi

# Set zsh as default shell (only if running interactively)
if [[ -n "$DOTFILES_MODULE" ]]; then
    if command -v zsh &> /dev/null && [[ "$(getent passwd $USER | cut -d: -f7)" != "$(which zsh)" ]]; then
        echo "ℹ️ You can set zsh as default with: chsh -s \$(which zsh)"
    fi
fi

# Install oh-my-zsh if not present
if [[ -z "$ZSH" ]]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --skip-chsh --skip-all
    echo "✅ Installed oh-my-zsh"
else
    echo "✅ oh-my-zsh already installed"
fi

# Install powerlevel10k theme
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
P10K_DIR="$ZSH_CUSTOM/themes/powerlevel10k"

if [[ ! -d "$P10K_DIR" ]]; then
    echo "Installing powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
    echo "✅ Installed powerlevel10k"
fi

# Set as theme in .zshrc if not already set
ZSHRC="$HOME/.zshrc"
if [[ -f "$ZSHRC" ]]; then
    if ! grep -q "powerlevel10k" "$ZSHRC"; then
        echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$ZSHRC"
    fi
fi

# Install useful plugins
AUTOSUGGESTIONS="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
if [[ ! -d "$AUTOSUGGESTIONS" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGESTIONS"
fi

SYNTAX_HIGHLIGHT="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
if [[ ! -d "$SYNTAX_HIGHLIGHT" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$SYNTAX_HIGHLIGHT"
fi

# Enable plugins in .zshrc if not already enabled
if [[ -f "$ZSHRC" ]]; then
    if ! grep -q "zsh-autosuggestions" "$ZSHRC"; then
        sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
    fi
fi

echo "✅ Shell configuration ready"
echo "ℹ️ Restart your shell or run: exec zsh"