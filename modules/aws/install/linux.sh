#!/usr/bin/env bash
# AWS CLI installation script for Linux

set -e

fail() {
    echo "$@"
    exit 1
}

echo "Installing AWS CLI v2 for Linux..."

# Install AWS CLI
if ! command -v aws >/dev/null 2>&1; then
    # Uninstallation instructions:
    # https://docs.aws.amazon.com/cli/latest/userguide/uninstall.html

    zip_file="/tmp/awscliv2.zip"

    if [[ -e "$zip_file" ]]; then
        fail "file already exists, exiting... ($zip_file)"
    fi

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$zip_file"

    cd "$(dirname "$zip_file")"
    sudo apt install -y unzip
    unzip "$zip_file"
    sudo ./aws/install

    rm "$zip_file"

    echo "✅ installed AWS CLI"
    aws --version
else
    echo "✅ AWS CLI already installed: $(aws --version)"
fi