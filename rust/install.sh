#!/bin/bash

set -e

ANSI_RED="\033[31m"
ANSI_RESET="\033[0m"


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
