#!/usr/bin/env bash

set -e

if ! which rustup; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
    echo "✅ installed rust toolchain (might need to 'exec zsh')"
else
    echo "✓ rustup is installed — checking for updates..."
    rustup self update
    rustup update stable

    rustup --version
    echo "✓ rustup is up to date"
    cargo --version
    echo "✓ cargo is up to date"
    rustc --version
    echo "✓ rustc is up to date"
fi
