#!/usr/bin/env bash

set -e

log() {
  echo "[$0] $*"
}

if [[ -z "$LOCAL_BUILD_LLAMACPP_FROM_SOURCE" ]]; then
  log "SKIPPING llama.cpp build"
  exit 0
fi

LLAMACPP_REPO=ggml-org/llama.cpp
LLAMACPP_BUILD_JOBS=8
LLAMACPP_BUILD_TARGET=llama-server
LLAMACPP_INSTALL_DIR="$HOME/bin"
LLAMACPP_DOWNLOAD_DIR="${LOCAL_LLAMACPP_DOWNLOAD_DIR:-$(mktemp -d)}"
if [[ ! -d "$LLAMACPP_DOWNLOAD_DIR" ]]; then
  mkdir -p "$LLAMACPP_DOWNLOAD_DIR"
fi
log "created $LLAMACPP_DOWNLOAD_DIR"

remove_temp_install_dir() {

  cd - || return 1
  log "TODO: rm -rf $LLAMACPP_DOWNLOAD_DIR" || return 1
  #
  # # rm -rf "$LLAMACPP_TEMP_INSTALL_DIR" || return 1
  # # log "removed $LLAMACPP_TEMP_INSTALL_DIR" || return 1
}

install_dependencies() {
  sudo apt install -y \
    libcurl4-openssl-dev \
    || return 1

  wget -qO- https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo tee /etc/apt/trusted.gpg.d/lunarg.asc || return 1
  sudo wget -qO /etc/apt/sources.list.d/lunarg-vulkan-noble.list http://packages.lunarg.com/vulkan/lunarg-vulkan-noble.list || return 1
  sudo apt update || return 1
  sudo apt install vulkan-sdk libopenblas-dev libopenblas0-openmp libopenblas0 \
    libopenblas-dev libopenblas-pthread-dev libopenblas-openmp-dev \
    libopenblas0-openmp libopenblas0-pthread vulkan-tools mesa-utils \
    || return 1

  log "✅ installed dependencies for llama.cpp build" || return 1
}

install_llamacpp() {
  install_dependencies || return 1

  log "🌐 fetching latest released tag name for llama.cpp" || return 1
  latest_tag_name="$(curl -s "https://api.github.com/repos/$LLAMACPP_REPO/releases/latest" | jq -r .tag_name)"
  log "🌐 pulling llama.cpp source code at the tag for the latest release ($latest_tag_name)" || return 1
  git clone --depth 1 --branch "$latest_tag_name" "https://github.com/$LLAMACPP_REPO" || return 1

  cd "$(basename "$LLAMACPP_REPO")" || return 1

  cmake -B build \
    -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=OpenBLAS \
    -DGGML_VULKAN=1 \
    -DLLAMA_CURL=ON \
    || return 1

  cmake \
    --build build \
    --config Release \
    --parallel "$LLAMACPP_BUILD_JOBS" \
    --target "$LLAMACPP_BUILD_TARGET" \
    || return 1

  ls build/bin || return 1

  "build/bin/$LLAMACPP_BUILD_TARGET" --version || return 1
  log "✅ built $LLAMACPP_BUILD_TARGET from source"

  cp "build/bin/$LLAMACPP_BUILD_TARGET" "$LLAMACPP_INSTALL_DIR" || return 1
  "$LLAMACPP_INSTALL_DIR/$LLAMACPP_BUILD_TARGET" --version || return 1
  log "✅ installed $LLAMACPP_INSTALL_DIR/$LLAMACPP_BUILD_TARGET"
}

cd "$LLAMACPP_DOWNLOAD_DIR"

install_llamacpp ||  {
  log "ERROR: could not install llama.cpp"
  remove_temp_install_dir
  exit 1
}

remove_temp_install_dir
