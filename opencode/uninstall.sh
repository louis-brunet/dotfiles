#!/usr/bin/env bash

set -e

npm uninstall -g opencode-ai

for dir in "$HOME/.config/opencode" "$HOME/.local/share/opencode"; do
    [[ -d "$dir" ]] && rm --verbose -r "$dir"
done
