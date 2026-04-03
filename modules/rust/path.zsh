#!/usr/bin/env sh

local cargo_env="$HOME/.cargo/env"
local cargo_bin="$HOME/.cargo/bin"

if [[ -f "$cargo_env" ]]; then
    source "$cargo_env"
else
    case ":${PATH}:" in
        *:"$cargo_bin":*)
            ;;
        *)
            # Prepending path in case a system-installed rustc needs to be overridden
            export PATH="$cargo_bin:$PATH"
            ;;
    esac
fi
