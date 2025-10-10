#!/usr/bin/env bash

# if [[ "$LOCAL_ENV" != "neoxia" ]]
# then
#     exit 0
# fi

set -e
set -x

fail() {
    echo "$@"
    exit 1
}

# Install AWS CLI
if ! which aws >/dev/null; then
    # Uninstallation instructions
    # https://docs.aws.amazon.com/cli/latest/userguide/uninstall.html

    zip_file="/tmp/awscliv2.zip"

    if [ -e "$zip_file" ]; then
        fail "file already exists, exiting... ($zip_file)"
    fi

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$zip_file"

    cd "$(dirname "$zip_file")"
    sudo apt install -y unzip
    unzip "$zip_file"
    sudo ./aws/install

    rm "$zip_file"

    echo "✅ installed aws CLI"
fi

# # Install CDK for Terraform
# if ! which cdktf >/dev/null; then
#     npm install --global cdktf-cli@latest
#     cdktf --version
#     echo "✅ installed cdktf (CDK for Terraform)"
# fi

