## Getting started

### Prerequisites
- Tested on Ubuntu 22.04, uses `apt` for package management.
- Install symlonk for symlink management.
    ```bash
    # install Rust
    ./rust/install.sh

    path_to_symlonk=path/to/symlonk/clone/
    git clone git@github.com:louis-brunet/symlonk.git "$path_to_symlonk"
    cd "$path_to_symlonk"
    PATH="$HOME/.cargo/bin:$PATH" cargo build --release

    mkdir ~/bin
    cp ./target/release/symlonk ~/bin
    ```

### First install
```bash
# create symlinks, prompt local git options if they are not set
# might need PATH="$HOME/bin:$PATH" if zsh and symlinks are not configured yet
./scripts/bootstrap

# run all ./*/install.sh scripts from topic folders
./scripts/install
```

## Symlinks
See [louis-brunet/symlonk](https://github.com/louis-brunet/symlonk) for documentation on managing symlinks.
