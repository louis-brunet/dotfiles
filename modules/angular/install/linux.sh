#!/usr/bin/env bash
# Angular CLI installation script

set -e

echo "Installing Angular CLI..."

# Check if npm is available
if ! command -v npm >/dev/null 2>&1; then
    echo "⚠️ npm not found, install node module first"
    exit 1
fi

# Check if already installed
if command -v ng >/dev/null 2>&1; then
    echo "✅ Angular CLI already installed: $(ng version --short 2>/dev/null | head -1)"
    exit 0
fi

# Install Angular CLI globally
npm install -g @angular/cli

echo "✅ Installed Angular CLI"
ng version | head -3