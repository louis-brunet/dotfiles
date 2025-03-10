if [ "$LOCAL_ENV" = "neoxia" ]; then
    gcloud_completion=/usr/share/google-cloud-sdk/completion.zsh.inc
    if [ -f "$gcloud_completion" ]; then
        source "$gcloud_completion"
    fi
fi
