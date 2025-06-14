#!/usr/bin/env bash

npm uninstall -g opencode-ai
rm --verbose -r "$HOME/.config/opencode" "$HOME/.local/share/opencode"
