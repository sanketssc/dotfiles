#!/usr/bin/env bash
# Core setup for a new Mac: nvim, tmux, starship, kitty (+ Monaspace), zed, zsh + nushell, git,
# worktrunk, herdr + plugins + Collie, Claude Code. Everything else in this repo (aerospace,
# karabiner, ...) is left out.
#
# XDG layout: nothing loose in ~. Config in ~/.config, data in ~/.local/share, cache in ~/.cache,
# state in ~/.local/state, binaries in ~/.local/bin. One variable list (XDG_ENV below) is exported
# before any tool runs, and written to /etc/zshenv (zsh), kitty's local.conf and the herdr
# LaunchAgent (both start nu, which does not read zshenv).
#
# Idempotent: safe to re-run. Invoked by `./install.sh --core`.
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
REPO="https://github.com/sanketssc/dotfiles.git"
BRANCH="mydots"
BACKUP="$HOME/.local/state/dotfiles-backup/$(date +%Y%m%d%H%M%S)"
HERDR_PLUGINS=(AltanS/collie persiyanov/herdr-reviewr plannotator/herdr-annotate nicosuave/memex levi-qiao/herdr-agent-usage)
NU=/opt/homebrew/bin/nu

# NAME=path-relative-to-$HOME
XDG_ENV=(
  XDG_CONFIG_HOME=.config
  XDG_DATA_HOME=.local/share
  XDG_CACHE_HOME=.cache
  XDG_STATE_HOME=.local/state
  CLAUDE_CONFIG_DIR=.config/claude
  AGENTS_HOME=.config/agents
  GOPATH=.local/share/go
  GOBIN=.local/bin
  CARGO_HOME=.local/share/cargo
  RUSTUP_HOME=.local/share/rustup
  BUN_INSTALL=.local/share/bun
  NPM_CONFIG_USERCONFIG=.config/npm/npmrc
  NPM_CONFIG_CACHE=.cache/npm
  GRADLE_USER_HOME=.local/share/gradle
  DOCKER_CONFIG=.config/docker
  ANDROID_USER_HOME=.local/share/android
  CP_HOME_DIR=.local/share/cocoapods
  OPENSRC_HOME=.cache/opensrc
  STARSHIP_CONFIG=.config/starship/starship.toml
  STARSHIP_CACHE=.cache/starship
  LESSHISTFILE=.local/state/less/history
  NODE_REPL_HISTORY=.local/state/node_repl_history
  PYTHON_HISTORY=.local/state/python/history
)

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m %s\n' "$*"; }

[[ "$(uname)" == "Darwin" ]] || { echo "install-core.sh is macOS-only"; exit 1; }

# 1. Xcode command line tools
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode command line tools — re-run this script when that finishes"
  xcode-select --install
  exit 0
fi

# 2. XDG environment — exported BEFORE any tool runs so nothing lands in ~
log "XDG environment"
for kv in "${XDG_ENV[@]}"; do export "${kv%%=*}=$HOME/${kv#*=}"; done
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_STATE_HOME/less" \
         "$XDG_STATE_HOME/python" "$XDG_STATE_HOME/zsh" "$XDG_CACHE_HOME/zsh" "$HOME/.local/bin" \
         "$XDG_CONFIG_HOME/npm" "$BACKUP"
export PATH="$HOME/.local/bin:$PATH"

# /etc/zshenv: zsh reads it before anything in ~, so ZDOTDIR moves all zsh files to ~/.config/zsh
BLOCK_BEGIN="# >>> dotfiles XDG layout >>>"
BLOCK_END="# <<< dotfiles XDG layout <<<"
block=$(
  echo "$BLOCK_BEGIN"
  for kv in "${XDG_ENV[@]}"; do printf 'export %s="$HOME/%s"\n' "${kv%%=*}" "${kv#*=}"; done
  echo 'export ZDOTDIR="$HOME/.config/zsh"'
  echo "$BLOCK_END"
)
current=$(cat /etc/zshenv 2>/dev/null || true)
without=$(printf '%s\n' "$current" | awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" '$0==b{skip=1} !skip{print} $0==e{skip=0}')
desired=$(printf '%s\n%s\n' "$without" "$block" | sed '/./,$!d')
if [[ "$current" != "$desired" ]]; then
  log "Writing /etc/zshenv (needs sudo):"
  printf '%s\n' "$block"
  printf '%s\n' "$desired" | sudo tee /etc/zshenv >/dev/null
fi

# 3. Homebrew
if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
  log "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
brew analytics off

# 4. dotfiles
if [[ ! -d "$DOTFILES/.git" ]]; then
  log "Cloning dotfiles"
  git clone --branch "$BRANCH" "$REPO" "$DOTFILES"
fi
cd "$DOTFILES"

# 5. packages
log "brew bundle (Brewfile.core)"
brew bundle --file "$DOTFILES/Brewfile.core"

log "npm globals"
for pkg in opensrc pnpm yarn eas-cli; do
  npm ls -g --depth=0 "$pkg" >/dev/null 2>&1 || npm install -g "$pkg" >/dev/null || warn "npm -g $pkg failed"
done

# Go tools the monorepo does NOT pin (it pins go/lefthook/mockery/gofumpt/golangci-lint/grpcurl in
# mise.toml → `task tools:install` in the repo). mise's Go, never brew's; binaries land in $GOBIN.
GO_VERSION="1.26.5"
GO_TOOLS=(golang.org/x/tools/gopls@latest honnef.co/go/tools/cmd/staticcheck@latest
          github.com/google/wire/cmd/wire@latest google.golang.org/protobuf/cmd/protoc-gen-go@latest
          google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest)
log "Go $GO_VERSION (mise) + go tools"
mise install "go@$GO_VERSION" >/dev/null
for t in "${GO_TOOLS[@]}"; do
  mise exec "go@$GO_VERSION" -- go install "$t" >/dev/null 2>&1 || warn "go install $t failed"
done

# 6. stow — anything real already at a target path is moved to $BACKUP first
backup_conflicts() { # $1 = stow dir, $2 = package, $3 = target dir
  local rel target
  while IFS= read -r rel; do
    rel=${rel#./}
    target="$3/$rel"
    if [[ -e "$target" && ! -L "$target" ]]; then
      mkdir -p "$BACKUP/$(dirname "$rel")"
      mv "$target" "$BACKUP/$rel"
      warn "backed up $target -> $BACKUP/$rel"
    fi
  done < <(cd "$1/$2" && find . -mindepth 1 \( -type f -o -type l \) -print)
}

PKGS=(nvim starship tmux kitty zed zsh nushell git worktrunk)
log "Stowing ${PKGS[*]} + herdr + scripts"
# ~/.config and ~/.local/bin must be real dirs, or stow folds them into one package (other apps
# and GOBIN would then write into the repo) — both were created in step 2.
for pkg in "${PKGS[@]}"; do
  backup_conflicts "$DOTFILES" "$pkg" "$HOME"
  stow -d "$DOTFILES" -t "$HOME" "$pkg"
done
# herdr keeps sockets, logs and session state in ~/.config/herdr: link only config.toml + local-plugins
backup_conflicts "$DOTFILES" herdr "$HOME"
stow -d "$DOTFILES" -t "$HOME" --no-folding herdr
# personal scripts go to ~/.local/bin (the old Mac keeps them in ~/scripts)
backup_conflicts "$DOTFILES/scripts" scripts "$HOME/.local/bin"
stow -d "$DOTFILES/scripts" -t "$HOME/.local/bin" scripts

# 7. kitty: XDG env + nushell for GUI-launched kitty (it doesn't read zshenv); file is gitignored
log "kitty local.conf (XDG env, nushell)"
{
  echo "# generated by install-core.sh — this Mac only (gitignored)"
  for kv in "${XDG_ENV[@]}"; do echo "env ${kv%%=*}=$HOME/${kv#*=}"; done
  echo "shell $NU --login"
} > "$DOTFILES/kitty/.config/kitty/local.conf"

# 8. nushell: prompt / zoxide / atuin / mise hooks (vendor autoload, outside the repo)
log "nushell hooks"
NU_AUTOLOAD="$XDG_DATA_HOME/nushell/vendor/autoload"
mkdir -p "$NU_AUTOLOAD"
starship init nu > "$NU_AUTOLOAD/starship.nu"
zoxide init nushell > "$NU_AUTOLOAD/zoxide.nu"
atuin init nu > "$NU_AUTOLOAD/atuin.nu"
mise activate nu > "$NU_AUTOLOAD/mise.nu"

# 9. tmux plugins — they are gitlinks in this repo, so a fresh clone has empty plugin dirs
TPM="$HOME/.config/tmux/.tmux/plugins/tpm"
if [[ ! -f "$TPM/tpm" ]]; then
  log "Installing tmux plugin manager"
  rm -rf "$TPM"
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM"
fi
log "Installing tmux plugins"
if tmux new-session -d -s tpm-install 2>/dev/null; then
  "$TPM/bin/install_plugins" >/dev/null || warn "tmux plugins: press prefix + I inside tmux"
  tmux kill-session -t tpm-install 2>/dev/null || true
else
  warn "tmux plugins: press prefix + I inside tmux"
fi

# 10. neovim plugins
log "Syncing neovim plugins"
nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || warn "nvim: open nvim and run :Lazy sync"

# 11. herdr server autostart — template + XDG env; SHELL=nu so herdr panes start nushell
log "herdr LaunchAgent"
HERDR_BIN="$(command -v herdr)"
PLIST="$HOME/Library/LaunchAgents/dev.herdr.server.plist"
PB=/usr/libexec/PlistBuddy
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
sed -e "s|__HOME__|$HOME|g" -e "s|__HERDR__|$HERDR_BIN|" \
  "$DOTFILES/launchd/dev.herdr.server.plist.template" > "$PLIST"
"$PB" -c "Set :EnvironmentVariables:SHELL $NU" "$PLIST"
for kv in "${XDG_ENV[@]}"; do
  "$PB" -c "Add :EnvironmentVariables:${kv%%=*} string $HOME/${kv#*=}" "$PLIST"
done
plutil -lint "$PLIST" >/dev/null
launchctl bootout "gui/$(id -u)/dev.herdr.server" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
sleep 2

# 12. herdr plugins
log "herdr plugins"
herdr plugin link "$HOME/.config/herdr/local-plugins/tab-numbers" >/dev/null 2>&1 || warn "tab-numbers: already linked or failed"
for p in "${HERDR_PLUGINS[@]}"; do
  if herdr plugin list 2>/dev/null | grep -q "github:$p@"; then continue; fi
  herdr plugin install "$p" --yes >/dev/null || warn "herdr plugin $p failed — retry: herdr plugin install $p --yes"
done
herdr config check || warn "herdr config check reported issues"

# 13. Claude config (private repo) — apply.sh honors CLAUDE_CONFIG_DIR / AGENTS_HOME exported above
if [[ -x "$HOME/claude-config/apply.sh" ]]; then
  log "Applying claude-config into $CLAUDE_CONFIG_DIR"
  "$HOME/claude-config/apply.sh"
else
  warn "claude-config not found:  gh repo clone sanketssc/claude-config ~/claude-config && ~/claude-config/apply.sh"
fi

# 14. anything still loose in ~ ?
log "Checking ~ for loose entries"
allowed='^(\.config|\.local|\.cache|\.ssh|\.Trash|\.CFUserTextEncoding|\.DS_Store|\.zsh_sessions)$'
loose=$(cd "$HOME" && ls -A | grep '^\.' | grep -Ev "$allowed" || true)
if [[ -n "$loose" ]]; then warn "loose in ~ (tools that ignore XDG — see below):"; printf '    %s\n' $loose; else echo "    none"; fi

cat <<'EOF'

Core setup done. Open a NEW kitty window (nushell) so the environment applies. Manual steps left:

  1. Claude:      `claude` → /login; re-add MCP servers (see ~/claude-config/README.md).
                  Add skills with `npx skills add <src> -g -a claude-code --copy` (plain `-g` recreates ~/.agents).
  2. Tailscale:   sudo brew services start tailscale && tailscale up
  3. GitHub SSH:  ssh-keygen -t ed25519 -f ~/.ssh/github; add it to GitHub; optional https→ssh rewrite in
                  ~/.config/git/config.local:  [url "ssh://git@github.com/"] insteadOf = https://github.com/
  4. invok3r:     key + ~/.ssh/config Host block (ssh-keygen, ssh-copy-id), then herdr machine add invok3r --label invok3r
  5. Collie:      join the crew led by invok3r as a member
                    (on invok3r)  collie crew invite
                    (here)        collie link
                                  collie crew join https://<invok3r MagicDNS name> @<token-file> --address <this Mac's MagicDNS name>:8787 --label <name>
                                  set COLLIE_HOST=<this Mac's tailnet IP> in the collie .env, then collie restart
                    (on invok3r)  collie restart
  6. Matiks:      clone matiks-monorepo, matiks-client, matiks-skills-hub into ~/Documents/matiks, then
                  monorepo: task tools:install && task hooks:install
                  client:   mise use node@22 (in the repo), corepack enable, yarn, (cd ios && pod install)
                  re-run ~/claude-config/apply.sh (company skill links need matiks-skills-hub)
  7. Xcode from the App Store; open Android Studio once for the SDK.
     GUI apps (Docker Desktop, Android Studio) don't read zshenv and may create ~/.docker / ~/.android.
  8. whoburnedmore: npx whoburnedmore (link this Mac), then npx whoburnedmore install-sync
EOF
