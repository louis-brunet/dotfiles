#!/usr/bin/env bash

if [[ -x "$(which npm)" ]] && [[ "$LOCAL_ENV" == "neoxia" ]]; then
    npm i -g @angular/cli
    echo "✅ installed angular CLI"
fi

