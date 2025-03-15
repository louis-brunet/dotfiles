#!/usr/bin/env bash

set -e

brew-install() {
  brew install $*
  echo "✅ installed $*"
}

brew-install llama.cpp
brew-install huggingface-cli 
