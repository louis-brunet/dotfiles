#!/usr/bin/env bash

set -x

fail() {
    echo $@
    exit 1
}

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

if ! which terraform >/dev/null; then
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

    wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

    gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint

    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

    sudo apt update

    sudo apt-get install terraform

    terraform -help

    echo "✅ installed terraform"
fi
