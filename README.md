## Getting started

### Prerequisites
- Tested on Ubuntu 24.04, uses `apt` for package management.
  - or homebrew for macOS
- Install symlonk for symlink management.
    ```bash
    # install Rust
    ./rust/install.sh

    path_to_symlonk=path/to/symlonk/clone/
    git clone git@github.com:louis-brunet/symlonk.git "$path_to_symlonk"
    cd "$path_to_symlonk"
    PATH="$HOME/.cargo/bin:$PATH" cargo build --release

    SYMLONK_INSTALL_PATH=~/bin
    mkdir -p "$SYMLONK_INSTALL_PATH"
    cp ./target/release/symlonk "$SYMLONK_INSTALL_PATH"
    ```

### First install
```bash
# create symlinks, prompt local git options if they are not set
# might need PATH="$SYMLONK_INSTALL_PATH:$PATH" if zsh and symlinks are not configured yet
python3 -m scripts.bootstrap --help
python3 -m scripts.bootstrap

# run all ./*/install.sh scripts from topic folders
# might need PATH="$SYMLONK_INSTALL_PATH:$HOME/.cargo/bin:$PATH"
./scripts/install
```

## Symlinks
See [louis-brunet/symlonk](https://github.com/louis-brunet/symlonk) for documentation on managing symlinks.
