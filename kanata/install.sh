# #!/usr/bin/env bash
#
# set -e
#
# is_wsl() {
#     grep 'microsoft' /proc/version >/dev/null
# }
#
# build_kanata() {
#     BIN_DIR="$HOME"/bin
#
#     mkdir -p "$BIN_DIR"
#
#     if is_wsl
#     then
#         if which powershell.exe >/dev/null
#         then
#             powershell.exe << EOF
# #                 winget install -e --id Git.Git
# Write-Host "Installing Rust..." -ForegroundColor Cyan
# $exePath = "$env:TEMP\rustup-init.exe"
#
# Write-Host "Downloading..."
# (New-Object Net.WebClient).DownloadFile('https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe', $exePath)
#
# Write-Host "Installing..."
# cmd /c start /wait $exePath -y
# Remove-Item $exePath
#
# $addPath = "$env:USERPROFILE\.cargo\bin"
# [Environment]::SetEnvironmentVariable
#      ($addPath, $env:Path, [System.EnvironmentVariableTarget]::Machine)
#
# reload
#
# cargo --version
# rustup --version
# rustc --version
# EOF
# # TODO: cargo build and mv
#         else
#             # TODO:
#         fi
#         # CARGO_TARGET_WINDOWS=x86_64-pc-windows-gnu
#         # WINDOWS_GCC=x86_64-w64-mingw32-gcc
#         # WINDOWS_GCC_APT_PACKAGE=mingw-w64
#         #
#         # if ! which "${WINDOWS_GCC}" >/dev/null
#         # then
#         #     echo "windows cross-compiler not found (${WINDOWS_GCC}), installing ${WINDOWS_GCC_APT_PACKAGE}"
#         #     sudo apt-get install -y ${WINDOWS_GCC_APT_PACKAGE}
#         # fi
#         # rustup target add "${CARGO_TARGET_WINDOWS}"
#         # cargo build --target "${CARGO_TARGET_WINDOWS}"
#         # mv ./target/"${CARGO_TARGET_WINDOWS}"/debug/kanata.exe "${BIN_DIR}" # TODO: /kanata , we check for "katana" in PATH
#     else # not WSL
#         cargo build
#         mv ./target/debug/kanata "${BIN_DIR}"
#     fi
# }
#
# # TODO: compiling on WSL seems to not work
# #
# if ! which kanata >/dev/null
# then
#     KANATA_PATH=$(mktemp -d)
#
#     git clone --depth 1 --branch v1.6.1 https://github.com/jtroo/kanata/ "${KANATA_PATH}"
#     cd "${KANATA_PATH}"
#
#     build_kanata
#
#     cd /
#     rm -rf "${KANATA_PATH}"
# fi
#
#
#
# # or:
# # cargo install kanata
