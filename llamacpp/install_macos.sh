#!/usr/bin/env bash

set -e

log() {
  echo "[$0] $*"
}

brew-install() {
  brew install $* || return 1
  log "✅ installed $*" || return 1
}

brew-install llama.cpp
brew-install huggingface-cli 
