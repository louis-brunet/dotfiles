#!/usr/bin/env bash
# Base module installation script for Linux
# Installs core system dependencies

set -e

echo "Installing base system dependencies (Linux)..."

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

# Linux: use apt
if command -v apt-get &> /dev/null; then
    # Check if we can use sudo non-interactively
    if sudo -n true 2>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y -qq git curl build-essential
        echo "✅ Installed git, curl, build-essential via apt"
    else
        echo "⚠️ sudo requires password (run manually): sudo apt-get install -y git curl build-essential"
        exit 0
    fi
else
    echo "⚠️ apt not found, skipping base installation"
    exit 0
fi

echo "✅ Base dependencies ready"
