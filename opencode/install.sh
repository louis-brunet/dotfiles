#!/usr/bin/env bash

set -e

# WARN: This makes the opencode installation specific to the current node version.
# This will fail in projects that automatically load a different node version, or
# when updating to a newer global node version, or when node has not been installed yet.
npm install -g opencode-ai@latest
