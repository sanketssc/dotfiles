# nushell env (new Mac, XDG layout). XDG_* and tool homes (GOPATH, CARGO_HOME, CLAUDE_CONFIG_DIR, ...)
# arrive from the environment (kitty local.conf, herdr LaunchAgent, /etc/zshenv); this adds PATH + defaults.
use std/util "path add"

# nu is also the login shell (chsh), and a login nu started by a terminal never reads
# /etc/zshenv. Load its XDG_ENV exports (written by install-core.sh) so one list stays
# the source of truth. Only `export NAME="$HOME/..."` lines are picked up.
if ("/etc/zshenv" | path exists) {
  open /etc/zshenv
  | lines
  | parse --regex '^export (?<name>\w+)="\$HOME/(?<value>[^"]*)"$'
  | update value {|r| $env.HOME | path join $r.value }
  | transpose -r -d
  | load-env
}

path add "/opt/homebrew/sbin" "/opt/homebrew/bin"
path add ($env.HOME | path join ".local/bin")   # personal scripts + GOBIN

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.STARSHIP_CONFIG = ($env.XDG_CONFIG_HOME? | default ($env.HOME | path join ".config") | path join "starship/starship.toml")

# Programs started from nu (Claude Code, scripts, tmux) should see a POSIX shell in $SHELL.
$env.SHELL = "/bin/zsh"
