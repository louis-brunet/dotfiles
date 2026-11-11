#!/usr/bin/env bash

set -e

echo "Installing Node.js LTS..."

# Install the latest LTS version of Node and set it globally
mise use --global node@lts

# Reshim to ensure binaries are mapped properly
mise reshim

echo "node $(mise exec -- node --version)"
echo "npm $(mise exec -- npm --version)"
echo "✅ installed node LTS and npm via mise"
echo "👉 Please run 'exec zsh' or restart your terminal to activate."
