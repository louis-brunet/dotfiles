#!/usr/bin/env bash

set -e

log() {
  echo "[$0] $*"
}

LLAMACPP_REPO=ggml-org/llama.cpp
LLAMACPP_BUILD_JOBS=8
LLAMACPP_BUILD_TARGET=llama-server
LLAMACPP_INSTALL_DIR="${LLAMACPP_INSTALL_DIR:-$(mktemp -d)}"
log "created $LLAMACPP_INSTALL_DIR"

remove_temp_install_dir() {

  cd -
  log "TODO: rm -rf $LLAMACPP_INSTALL_DIR"
  #
  # # rm -rf "$LLAMACPP_TEMP_INSTALL_DIR"
  # # log "removed $LLAMACPP_TEMP_INSTALL_DIR"
}

install_dependencies() {
  sudo apt install libcurl4-openssl-dev
  log "✅ installed dependencies for llama.cpp build"
}

install_llamacpp() {
  install_dependencies
  latest_tag_name="$(curl -s "https://api.github.com/repos/$LLAMACPP_REPO/releases/latest" | jq -r .tag_name)"
  log "🌐 pulling llama.cpp source code at the tag for the latest release ($latest_tag_name)"
  git clone --depth 1 --branch "$latest_tag_name" "https://github.com/$LLAMACPP_REPO"
  cd "$(basename "$LLAMACPP_REPO")"
  cmake -B build \
    -DGGML_VULKAN=ON \
    -DLLAMA_CURL=ON
  cmake \
    --build build \
    --config Release \
    --parallel "$LLAMACPP_BUILD_JOBS" \
    --target "$LLAMACPP_BUILD_TARGET"
  ls build/bin
  log "✅ built $LLAMACPP_BUILD_TARGET from source"
}

cd "$LLAMACPP_INSTALL_DIR"

install_llamacpp ||  {
  log "ERROR: could not install llama.cpp"
  remove_temp_install_dir
  exit 1
}

remove_temp_install_dir
