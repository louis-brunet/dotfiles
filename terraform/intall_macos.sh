#!/usr/bin/env bash


set -e
set -x

fail() {
    echo "$@"
    exit 1
}

# Install or update Terraform CLI
echo "Installing Terraform CLI"

brew tap hashicorp/tap
brew install hashicorp/tap/terraform

echo "✅ installed terraform"

# Install CDK for Terraform
# if ! which cdktf >/dev/null; then
    npm install --global cdktf-cli@latest
    cdktf --version
    echo "✅ installed cdktf (CDK for Terraform)"
# fi

