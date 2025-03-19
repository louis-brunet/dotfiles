if [ "$LOCAL_ENV" = "neoxia" ]; then
    gcloud_search_locations=(
        "$HOME/google-cloud-sdk"
        "/opt/homebrew/share/google-cloud-sdk"
        "/usr/share/google-cloud-sdk"
    )

    for gcloud_sdk_location in $gcloud_search_locations; do
        gcloud_completion="$gcloud_sdk_location"/completion.zsh.inc
        if [[ -f "${gcloud_completion}" ]]; then
            source "$gcloud_completion"
            break
        fi
    done
fi
