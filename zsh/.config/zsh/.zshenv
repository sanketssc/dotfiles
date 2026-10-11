# Read by every zsh. On the XDG layout (new Mac) /etc/zshenv has already exported
# XDG_*, ZDOTDIR and the tool homes (CARGO_HOME, GOPATH, ...) before this runs.

# rust toolchain env from rustup (old layout: ~/.cargo; XDG layout: $CARGO_HOME)
[ -f "${CARGO_HOME:-$HOME/.cargo}/env" ] && . "${CARGO_HOME:-$HOME/.cargo}/env"

# Android builds: JDK 17 from brew's keg-only openjdk@17 (SDKMAN in .zshrc still wins where it is
# installed) and Android Studio's SDK. nushell's env.nu sets the same pair.
if [[ $OSTYPE == darwin* ]]; then
  [ -z "${JAVA_HOME:-}" ] && [ -d /opt/homebrew/opt/openjdk@17 ] && export JAVA_HOME=/opt/homebrew/opt/openjdk@17
  export ANDROID_HOME="$HOME/Library/Android/sdk"
else
  [ -z "${JAVA_HOME:-}" ] && [ -d /usr/lib/jvm/java-17-openjdk ] && export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
  export ANDROID_HOME="$HOME/Android/Sdk"
fi

# Linux (invok3r): `ssh host cmd` (herdr remote, T3) runs a non-interactive zsh that reads only
# this file, so user-installed binaries must be on PATH here, not in .zprofile/.zshrc.
if [[ $OSTYPE == linux* ]]; then
  typeset -U path
  for _d in "$HOME/go/bin" "$HOME/.cargo/bin" "${BUN_INSTALL:-$HOME/.bun}/bin" "$HOME/.local/bin"; do
    [[ -d $_d ]] && path=("$_d" $path)
  done
  unset _d
  export PATH
fi
