#!/usr/bin/env bash
# AWS CLI installation script for macOS

set -e

fail() {
    echo "$@"
    exit 1
}

echo "Installing AWS CLI v2 for macOS..."

# Install AWS CLI
# Uninstallation instructions:
# https://docs.aws.amazon.com/cli/latest/userguide/uninstall.html

curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
rm AWSCLIV2.pkg

echo "✅ installed AWS CLI"
aws --version