#!/bin/bash

set -e

brew install neovim
brew install ripgrep

if ! which tree-sitter >/dev/null
then
    if which npm >/dev/null
    then
        npm install -g tree-sitter-cli
        echo "✅ installed tree-sitter CLI to install languages (latex) from grammar"
    else
        echo "⚠️: missing npm to install tree-sitter-cli to compile from grammar"
    fi

fi
