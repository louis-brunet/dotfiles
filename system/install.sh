#!/bin/bash

# install the recommended nerd font for the theme powerlevel10k 
FONTS_DIR=~/.local/share/fonts/truetype
mkdir -p "$FONTS_DIR"
regular_file_name="MesloLGS NF Regular.ttf"
if [ ! -f "$FONTS_DIR/$regular_file_name" ]
then
    wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf && mv "$regular_file_name" "$FONTS_DIR"
    wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf && mv MesloLGS\ NF\ Bold.ttf "$FONTS_DIR"
    wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf && mv MesloLGS\ NF\ Italic.ttf "$FONTS_DIR"
    wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf && mv MesloLGS\ NF\ Bold\ Italic.ttf "$FONTS_DIR"
    echo "✅ installed nerd font for powerlevel10k (MesloLGS NF)"
    echo -e "❗ if the following doesn't look like Tux, set $regular_file_name as the terminal font: \uf31a"
fi

