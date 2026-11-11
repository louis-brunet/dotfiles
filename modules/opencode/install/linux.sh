#!/usr/bin/env bash

set -e

# WARN: This makes the opencode installation specific to the current node version.
# This will fail in projects that automatically load a different node version, or
# when updating to a newer global node version, or when node has not been installed yet.
if npm install -g opencode-ai@latest && opencode_version=$(opencode --version); then
    echo "✅ installed opencode $opencode_version"
else
    echo "❌ could not install opencode"
    exit 1
fi

if npm install -g ts-node && ts_node_version=$(npx ts-node --version); then
    echo "✅ installed ts-node $ts_node_version for OpenCode"
else
    echo "❌ could not install ts-node (OpenCode)"
    exit 1
fi

