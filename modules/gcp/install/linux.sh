#!/usr/bin/env bash

if [[ "$LOCAL_ENV" != "neoxia" && "$LOCAL_INSTALL_GCLOUD" != "true" ]]
then
    exit 0
fi

set -e
# set -x

# fail() {
#     echo $@
#     exit 1
# }

# Install gcloud CLI
if ! which gcloud; then
    sudo apt-get update -y
    sudo apt-get install -y apt-transport-https ca-certificates gnupg curl

    # Import the Google Cloud public key
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor --yes -o /usr/share/keyrings/cloud.google.gpg

    # Add the gcloud CLI distribution URI as a package source
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

    sudo apt-get update
    sudo apt-get install -y google-cloud-cli

    echo "✅ installed gcloud CLI"
fi


