#!/usr/bin/env sh

set -e

softwareupdate --install-rosetta --agree-to-license

brew install --cask rancher

# NOTE: Rancher Desktop GUI needs to manually be opened (and manual PATH modification selected) for $HOME/.rd/bin/ to be created
