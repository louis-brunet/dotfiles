# NOTE: completions for this function are defined in ../functions/_mann because
# ../functions is in `$fpath`
mann() {
    if [[ $# -lt 1 ]]; then
        echo "usage: $0 <man_args...>" >&2
        return 1
    fi
    # Open the man page, close other windows, open table of contents on the
    # right side, put cursor back in man page.
    nvim \
        +"Man $*" \
        +'wincmd o' \
        +'norm gO' \
        +'wincmd L' \
        +'wincmd w'
}
