#!/bin/bash

set -e

echo 'Looking for qmk executable'
if ! which qmk
then
    sudo apt install -y git python3-pip
    # NOTE: might need  --break-system-packages if "externally managed environment" error
    python3 -m pip install --user qmk

    echo "✅ installed qmk"

fi


if [[ -n "$PROJECTS" ]]; then
    qmk_home="${PROJECTS}/qmk_firmware"
    qmk_repo=louis-brunet/qmk_firmware
    qmk_branch=bluetooth_playground

    qmk setup --home "$qmk_home" --branch "$qmk_branch" "$qmk_repo"
fi
