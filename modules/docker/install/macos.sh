#!/usr/bin/env sh
# Docker installation script for macOS

set -e

echo "Installing Docker for macOS..."

# Install Rosetta if needed
if ! /usr/bin/pgrep -q oah; then
    softwareupdate --install-rosetta --agree-to-license || true
fi

# Check if Docker is already installed
if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker already installed: $(docker --version)"
    exit 0
fi

# Install Rancher Desktop (free, includes Docker)
if command -v brew >/dev/null 2>&1; then
    brew install --cask rancher
    echo "✅ Installed Rancher Desktop"
    echo "ℹ️  Open Rancher Desktop app and enable Docker CLI in preferences"
    echo "ℹ️  You may need to add ~/.rd/bin to your PATH"
else
    echo "⚠️ Homebrew not found, cannot install Rancher Desktop"
    exit 1
fi