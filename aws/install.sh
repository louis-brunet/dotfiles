#!/usr/bin/env bash

# if [[ "$LOCAL_ENV" != "neoxia" ]]
# then
#     exit 0
# fi

set -e
set -x

fail() {
    echo $@
    exit 1
}

# Install AWS CLI
if ! which aws >/dev/null; then
    # Uninstallation instructions
    # https://docs.aws.amazon.com/cli/latest/userguide/uninstall.html

    zip_file="/tmp/awscliv2.zip"

    if [ -e "$zip_file"]; then
        fail "file already exists, exiting... ($zip_file)"
    fi

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$zip_file"

    cd "$(dirname "$zip_file")"
    unzip "$zip_file"
    sudo ./aws/install

    rm "$zip_file"

    echo "✅ installed aws CLI"
fi

# Install Terraform CLI
if ! which terraform >/dev/null; then
    echo "Installing Terraform CLI"

    sudo snap install --classic terraform

    # wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    # echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    # sudo apt update && sudo apt install terraform

    terraform -help

    echo "✅ installed terraform"
fi

# # Install CDK for Terraform
# if ! which cdktf >/dev/null; then
#     npm install --global cdktf-cli@latest
#     cdktf --version
#     echo "✅ installed cdktf (CDK for Terraform)"
# fi

