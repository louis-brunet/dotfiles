#!/usr/bin/env bash
# Base module installation script for macOS
# Installs core system dependencies

set -e

echo "Installing base system dependencies (macOS)..."

# Check if requirements are already met
if command -v git &> /dev/null && command -v curl &> /dev/null; then
    echo "✅ git and curl already available"

    if command -v make &> /dev/null; then
        echo "✅ build tools already available"
    else
        echo "⚠️ make not found - some builds may fail"
    fi
    echo "✅ Base dependencies ready (using existing tools)"
    exit 0
fi

# macOS: use Homebrew
if command -v brew &> /dev/null; then
    brew install git curl
    echo "✅ Installed git and curl via Homebrew"
else
    echo "⚠️ Homebrew not found, skipping base installation"
    exit 0
fi

echo "✅ Base dependencies ready"
