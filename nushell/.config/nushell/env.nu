# nushell env (new Mac, XDG layout). XDG_* and tool homes (GOPATH, CARGO_HOME, CLAUDE_CONFIG_DIR, ...)
# arrive from the environment (kitty local.conf, herdr LaunchAgent, /etc/zshenv); this adds PATH + defaults.
use std/util "path add"

path add "/opt/homebrew/sbin" "/opt/homebrew/bin"
path add ($env.HOME | path join ".local/bin")   # personal scripts + GOBIN

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.STARSHIP_CONFIG = ($env.XDG_CONFIG_HOME? | default ($env.HOME | path join ".config") | path join "starship/starship.toml")

# Programs started from nu (Claude Code, scripts, tmux) should see a POSIX shell in $SHELL.
$env.SHELL = "/bin/zsh"
