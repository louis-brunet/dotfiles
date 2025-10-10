#!/usr/bin/env bash


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

    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
    sudo installer -pkg AWSCLIV2.pkg -target /
    rm AWSCLIV2.pkg

    echo "✅ installed aws CLI"
fi

# # Install CDK for Terraform
# if ! which cdktf >/dev/null; then
#     npm install --global cdktf-cli@latest
#     cdktf --version
#     echo "✅ installed cdktf (CDK for Terraform)"
# fi

