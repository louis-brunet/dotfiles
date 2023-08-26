#!/bin/bash 

set -e
# echo "⚠️  TODO: uncomment nvim install script (commented bc docker ubuntu doesn't support snap)"

sudo snap install nvim --classic
nvim --version
echo "✅ installed nvim"

sudo apt install ripgrep
rg --version
echo "✅ installed ripgrep for Telescope"

