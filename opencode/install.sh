#!/usr/bin/env bash

# NOTE: This makes the opencode installation specific to the current node version.
# This will fail in projects that automatically load a different node version, or
# when updating to a newer global node version.
npm install -g opencode-ai
