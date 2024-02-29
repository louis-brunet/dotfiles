#!/usr/bin/env sh

if ! which docker >/dev/null; then
    curl -fsSL https://get.docker.com | sudo sh

    docker --version
    docker compose version

    echo "✅ installed docker"
fi

if ! groups | grep -q 'docker'; then
    sudo usermod -aG docker "$USER"
    echo "✅ created docker group"
fi
