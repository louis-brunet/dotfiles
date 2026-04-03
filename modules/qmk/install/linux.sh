#!/usr/bin/env bash
# QMK firmware tooling installation script
# Note: Currently disabled - uncomment to enable

set -e

echo "QMK installation is currently disabled"
echo "To enable, edit modules/qmk/install/linux.sh and uncomment the commands below"

# The following would install QMK:
# sudo apt install -y git python3-pip
# python3 -m pip install --user qmk
# echo "✅ Installed QMK"

# Optional: setup QMK firmware repository
# if [[ -n "$PROJECTS" ]]; then
#     qmk_home="${PROJECTS}/qmk_firmware"
#     qmk_repo=louis-brunet/qmk_firmware
#     qmk_branch=bluetooth_playground
#     qmk setup --home "$qmk_home" --branch "$qmk_branch" "$qmk_repo"
# fi

echo "ℹ️ QMK is optional - skipping installation"