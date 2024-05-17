<!-- ## Prerequisites -->
<!---->
<!-- Tested on Ubuntu 22.04 -->
<!---->
<!-- ### zsh as the default shell -->
<!---->
<!-- 1. Install -->
<!---->
<!-- Check if installed: `zsh --version` (expect 5.0.8 or more recent) -->
<!---->
<!-- ```bash -->
<!-- sudo apt install zsh -->
<!-- ``` -->
<!---->
<!-- 2. Set as default shell -->
<!---->
<!-- Check if it is already the default shell: `echo $SHELL` -->
<!---->
<!-- ```bash -->
<!-- chsh -s $(which zsh) -->
<!-- ``` -->
<!---->
<!-- Restart the terminal. -->
<!---->
<!-- ### oh-my-zsh to manage zsh plugins and themes -->
<!---->
<!-- ```bash -->
<!-- sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" -->
<!-- ``` -->
<!---->
<!-- ### powerlevel10k theme for zsh -->
<!---->
<!-- 1. install the [recommended](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k) nerd font -->
<!---->
<!-- ```bash -->
<!-- mkdir -p ~/.local/share/fonts/truetype -->
<!-- wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf && mv MesloLGS\ NF\ Regular.ttf ~/.local/share/fonts/truetype/  -->
<!-- wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf && mv MesloLGS\ NF\ Bold.ttf ~/.local/share/fonts/truetype/  -->
<!-- wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf && mv MesloLGS\ NF\ Italic.ttf ~/.local/share/fonts/truetype/  -->
<!-- wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf && mv MesloLGS\ NF\ Bold\ Italic.ttf ~/.local/share/fonts/truetype/  -->
<!-- ``` -->
<!---->
<!-- Restart the terminal (?) and set the font as the terminals default font. For Ubuntu's terminal, Preferences > Profiles > {current profile} > Text > Custom Font. -->
<!---->
<!-- 2. manage the p10k theme with oh-my-zsh -->
<!---->
<!-- ```bash -->
<!-- git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k -->
<!-- ``` -->
<!---->
<!-- Add to `.zshrc` : `ZSH_THEME="powerlevel10k/powerlevel10k"` -->
<!---->
<!-- ### tmux -->
<!---->
<!-- ```bash -->
<!-- sudo apt install tmux -->
<!-- ``` -->
<!---->
<!-- ### nvim -->
<!---->
<!-- Check version `nvim --version` (expect 0.9.1+) -->
<!---->
<!-- ```bash -->
<!-- sudo snap install nvim --classic -->
<!-- ``` -->

## Getting started

### Prerequisites
- Tested on Ubuntu 22.04, uses `apt` for package management.
- Install symlonk for symlink management.
    ```bash
    path_to_symlonk=path/to/symlonk/clone/
    git clone git@github.com:louis-brunet/symlonk.git "$path_to_symlonk"
    cd "$path_to_symlonk"
    cargo build --release

    mkdir ~/bin
    cp ./target/release/symlonk ~/bin
    ```

### First install
```bash
# create symlinks, prompt local git options
# might need PATH="$HOME/bin:$PATH" if zsh and symlinks are not configured yet
./scripts/bootstrap

# run all ./*/install.sh scripts from topic folders
./scripts/install
```

## Symlinks
See [louis-brunet/symlonk](https://github.com:louis-brunet/symlonk) for documentation on managing symlinks.
