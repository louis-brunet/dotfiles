#!/usr/bin/env bash

if which npm >/dev/null && [[ "$LOCAL_ENV" = "neoxia" ]]; then
    npm i -g @angular/cli
    echo "✅ installed angular CLI"
fi

