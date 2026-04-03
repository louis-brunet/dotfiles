#!/usr/bin/env bash

set -e

if ! which rustup; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    echo "✅ installed rust toolchain (might need to 'exec zsh')"
else
    rustup --version
    echo "✅ rustup is installed"

    cargo --version
    echo "✅ cargo is installed"

    rustc --version
    echo "✅ rustc is installed"
fi
