function vscode_enable_shell_integration() {
    local vscode_executable=""
    local candidate_vscode_executables=(
        "code"
        "/Applications/Visual Studio Code.app/Contents/Code"
    )
    local candidate

    for candidate in "${candidate_vscode_executables[@]}"; do
        if command -v "$candidate" &> /dev/null; then
            vscode_executable="$candidate"
            break
        fi
    done

    [[ -n "$vscode_executable" ]] || return

    [[ "$TERM_PROGRAM" == "vscode" ]] && . "$($vscode_executable --locate-shell-integration-path zsh)"
}
vscode_enable_shell_integration
