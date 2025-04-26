mann() {
    if [[ $# -lt 1 ]]; then
        echo "usage: $0 <man_args...>" >&2
        return 1
    fi
    nvim +"Man $*" +"wincmd o"
}
