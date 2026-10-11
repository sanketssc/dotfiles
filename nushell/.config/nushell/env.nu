# nushell env (new Mac, XDG layout). XDG_* and tool homes (GOPATH, CARGO_HOME, CLAUDE_CONFIG_DIR, ...)
# arrive from the environment (kitty local.conf, herdr LaunchAgent, /etc/zshenv); this adds PATH + defaults.
use std/util "path add"

# nu is also the login shell (chsh), and a login nu started by a terminal never reads
# /etc/zshenv. Load its XDG_ENV exports (written by install-core.sh) so one list stays
# the source of truth. Only `export NAME="$HOME/..."` lines are picked up.
# Arch's zsh reads /etc/zsh/zshenv instead (invok3r: XDG base dirs + ZDOTDIR only).
let macos = ($nu.os-info.name == "macos")
let zshenv = if $macos { "/etc/zshenv" } else { "/etc/zsh/zshenv" }
if ($zshenv | path exists) {
  open $zshenv
  | lines
  | parse --regex '^export (?<name>\w+)="\$HOME/(?<value>[^"]*)"$'
  | update value {|r| $env.HOME | path join $r.value }
  | transpose -r -d
  | load-env
}

if $macos {
  path add "/opt/homebrew/sbin" "/opt/homebrew/bin"
} else {
  # what fish's conf.d/00-path.fish added on invok3r (zsh: .zshenv); missing dirs are skipped
  for d in [go/bin .cargo/bin .bun/bin] {
    let dir = ($env.HOME | path join $d)
    if ($dir | path exists) { path add $dir }
  }
}
path add ($env.HOME | path join ".local/bin")   # personal scripts + GOBIN

$env.EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.STARSHIP_CONFIG = ($env.XDG_CONFIG_HOME? | default ($env.HOME | path join ".config") | path join "starship/starship.toml")

# Programs started from nu (Claude Code, scripts, tmux) should see a POSIX shell in $SHELL.
if ("/bin/zsh" | path exists) { $env.SHELL = "/bin/zsh" }

# Android builds (matiks-client): Gradle 9 + AGP need JDK 17 (brew's openjdk@17 is keg-only, so
# macOS has no Java otherwise); the SDK is Android Studio's. Every shell and pane is nu, so this
# reaches gradle, Claude sessions and worktrees without a local.properties.
# Signing secrets are NOT here (this repo is public): android-release reads them from the Keychain.
# Linux: Arch's jdk17-openjdk and Android Studio's default SDK dir, set only when installed.
let java_home = if $macos { "/opt/homebrew/opt/openjdk@17" } else { "/usr/lib/jvm/java-17-openjdk" }
if ($java_home | path exists) {
  $env.JAVA_HOME = $java_home
  path add ($env.JAVA_HOME | path join "bin")
}
$env.ANDROID_HOME = ($env.HOME | path join (if $macos { "Library/Android/sdk" } else { "Android/Sdk" }))
path add ($env.ANDROID_HOME | path join "platform-tools") ($env.ANDROID_HOME | path join "emulator")

# Keep this last. `mise activate nu` bakes the PATH it sees into its script, so a copy generated
# once (install-core) froze an old PATH and reset it on every prompt, dropping each `path add`
# above. Regenerate it here, after all PATH edits; vendor autoload runs after env.nu + config.nu.
# A parent shell's mise session (__MISE_ORIG_PATH etc., e.g. `exec nu` or a pane started from
# zsh) would make mise restore that parent's PATH instead, so drop it first.
# Write to a per-process temp file and rename it into place: shells starting together (herdr
# restoring panes) would otherwise interleave their writes and leave an unparsable file.
if (which mise | is-not-empty) {
  hide-env --ignore-errors __MISE_ORIG_PATH __MISE_DIFF __MISE_SESSION MISE_SHELL
  let mise_nu = ($nu.data-dir | path join "vendor/autoload/mise.nu")
  let tmp = $"($mise_nu).($nu.pid).tmp"
  ^mise activate nu | save --force $tmp
  mv --force $tmp $mise_nu
}
