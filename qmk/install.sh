#!/bin/bash

set -e

echo 'Looking for qmk executable'
if ! which qmk
then
    sudo apt install -y git python3-pip
    python3 -m pip install --user qmk

    echo "✅ installed qmk"

fi


if [[ -n $PROJECTS ]]; then
    home="${PROJECTS}/qmk_firmware"
    repo=louis-brunet/qmk_firmware
    branch=bluetooth_playground

    qmk setup --home "$home" --branch "$branch" "$repo"
fi
