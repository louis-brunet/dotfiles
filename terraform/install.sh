#!/usr/bin/env bash

set -e
set -x

fail() {
    echo "$@"
    exit 1
}

# Install or update Terraform CLI
echo "Installing Terraform CLI"

# sudo snap install --classic terraform

wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update && sudo apt install terraform
terraform -help
echo "✅ installed terraform"

# # Install CDK for Terraform
# if ! which cdktf >/dev/null; then
#     npm install --global cdktf-cli@latest
#     cdktf --version
#     echo "✅ installed cdktf (CDK for Terraform)"
# fi

