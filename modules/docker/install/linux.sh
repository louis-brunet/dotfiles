#!/usr/bin/env sh
# Docker installation script for Linux

set -e

echo "Installing Docker for Linux..."

if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker already installed: $(docker --version)"
    exit 0
fi

# Install Docker via official script
curl -fsSL https://get.docker.com | sudo sh

docker --version
docker compose version

echo "✅ Installed Docker"

# Add user to docker group if not already
if ! groups | grep -q docker; then
    sudo usermod -aG docker "$USER"
    echo "✅ Added user to docker group (may require logout/login)"
fi