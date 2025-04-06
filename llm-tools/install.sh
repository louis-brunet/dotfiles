#!/usr/bin/env bash

set -e

log() {
  echo "=> [$0] $*"
}

_download_llm_tools_asset() {
  if [[ "$#" -ne 2 ]]; then
    log "Usage: $0 <release_asset> <output_location>" >&2
    return 1
  fi
  local asset="$1"
  local output_location="$2"

  local repo_owner=louis-brunet
  local repo_name=llm-tools
  local repo="$repo_owner/$repo_name"
  local release_tag="next" # FIXME: use latest once first release has been made
  local asset_url="https://github.com/$repo/releases/download/$release_tag/$asset"

  log "downloading $asset_url to $output_location"
  curl \
    --output "$output_location" \
    --create-dirs \
    --silent --show-error --location \
    "$asset_url" || return 1
}

_install_llm_tools() {
  local app_name=llm-tools

  local release_asset_cli="cli.js"
  local curl_cli_output="$HOME/bin/$app_name"
  _download_llm_tools_asset "$release_asset_cli" "$curl_cli_output"

  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  local zsh_plugins_dir="${zsh_custom}/plugins"
  if [[ -d "$zsh_plugins_dir/$app_name" ]]; then
    (cd "$zsh_plugins_dir" && rm -r "$app_name")
  fi
  local release_asset_zsh_plugin="zsh-plugin.tgz"
  local temp_download_dir
  temp_download_dir="$(mktemp -d)" || return 1
  local curl_zsh_plugin_output="$temp_download_dir/$release_asset_zsh_plugin"
  _download_llm_tools_asset "$release_asset_zsh_plugin" "$curl_zsh_plugin_output"
  tar -C "$temp_download_dir" -xvf "$curl_zsh_plugin_output" || return 1
  log "moving $temp_download_dir/$app_name to $zsh_plugins_dir"
  mv "$temp_download_dir/$app_name" "$zsh_plugins_dir" || return 1
  rm -r "$temp_download_dir" || return 1

  log "installed $zsh_plugins_dir/$app_name"
}

_install_llm_tools
