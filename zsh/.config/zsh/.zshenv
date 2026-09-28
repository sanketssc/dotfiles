# Read by every zsh. On the XDG layout (new Mac) /etc/zshenv has already exported
# XDG_*, ZDOTDIR and the tool homes (CARGO_HOME, GOPATH, ...) before this runs.

# rust toolchain env from rustup (old layout: ~/.cargo; XDG layout: $CARGO_HOME)
[ -f "${CARGO_HOME:-$HOME/.cargo}/env" ] && . "${CARGO_HOME:-$HOME/.cargo}/env"
