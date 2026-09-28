#!/usr/bin/env bash
# Core setup for a new Mac: nvim, tmux, starship, kitty (+ Monaspace), herdr + plugins + Collie,
# Claude Code, nushell. Everything else in this repo (aerospace, karabiner, ...) is left out.
# Idempotent: safe to re-run. Invoked by `./install.sh --core`.
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
REPO="https://github.com/sanketssc/dotfiles.git"
BRANCH="mydots"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"
HERDR_PLUGINS=(AltanS/collie persiyanov/herdr-reviewr plannotator/herdr-annotate nicosuave/memex levi-qiao/herdr-agent-usage)

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m %s\n' "$*"; }

[[ "$(uname)" == "Darwin" ]] || { echo "install-core.sh is macOS-only"; exit 1; }

# 1. Xcode command line tools
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode command line tools — re-run this script when that finishes"
  xcode-select --install
  exit 0
fi

# 2. Homebrew
if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
  log "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
brew analytics off

# 3. dotfiles
if [[ ! -d "$DOTFILES/.git" ]]; then
  log "Cloning dotfiles"
  git clone --branch "$BRANCH" "$REPO" "$DOTFILES"
fi
cd "$DOTFILES"

# 4. packages
log "brew bundle (Brewfile.core)"
brew bundle --file "$DOTFILES/Brewfile.core"

# 4b. npm globals (brew node)
log "npm globals"
for pkg in opensrc pnpm yarn eas-cli; do
  npm ls -g --depth=0 "$pkg" >/dev/null 2>&1 || npm install -g "$pkg" >/dev/null || warn "npm -g $pkg failed"
done

# 4c. Go tools the monorepo does NOT pin (it pins go/lefthook/mockery/gofumpt/golangci-lint/grpcurl
#     in mise.toml → `task tools:install` in the repo). Uses mise's Go, never brew's.
GO_VERSION="1.26.5"
GO_TOOLS=(golang.org/x/tools/gopls@latest honnef.co/go/tools/cmd/staticcheck@latest
          github.com/google/wire/cmd/wire@latest google.golang.org/protobuf/cmd/protoc-gen-go@latest
          google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest)
log "Go $GO_VERSION (mise) + go tools"
mise install "go@$GO_VERSION" >/dev/null
for t in "${GO_TOOLS[@]}"; do
  mise exec "go@$GO_VERSION" -- go install "$t" >/dev/null 2>&1 || warn "go install $t failed"
done

# 5. stow — anything real already at a target path is moved to $BACKUP first
backup_conflicts() {
  local pkg=$1 rel target
  while IFS= read -r rel; do
    rel=${rel#./}
    target="$HOME/$rel"
    if [[ -e "$target" && ! -L "$target" ]]; then
      mkdir -p "$BACKUP/$(dirname "$rel")"
      mv "$target" "$BACKUP/$rel"
      warn "backed up $target -> $BACKUP/$rel"
    fi
  done < <(cd "$DOTFILES/$pkg" && find . -mindepth 1 -type f -print)
}

log "Stowing nvim starship tmux kitty zed herdr"
# ~/.config must be a real dir, or stow folds it into the first package (other apps would then write into the repo)
mkdir -p "$HOME/.config"
for pkg in nvim starship tmux kitty zed; do
  backup_conflicts "$pkg"
  stow -t "$HOME" "$pkg"
done
# herdr keeps sockets, logs and session state in ~/.config/herdr: link only config.toml + local-plugins
backup_conflicts herdr
stow --no-folding -t "$HOME" herdr

# 6. tmux plugins — they are gitlinks in this repo, so a fresh clone has empty plugin dirs
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

# 7. neovim plugins
log "Syncing neovim plugins"
nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || warn "nvim: open nvim and run :Lazy sync"

# 8. herdr server autostart (LaunchAgent from template)
log "herdr LaunchAgent"
HERDR_BIN="$(command -v herdr)"
PLIST="$HOME/Library/LaunchAgents/dev.herdr.server.plist"
mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
sed -e "s|__HOME__|$HOME|g" -e "s|__HERDR__|$HERDR_BIN|" \
  "$DOTFILES/launchd/dev.herdr.server.plist.template" > "$PLIST"
plutil -lint "$PLIST" >/dev/null
launchctl bootout "gui/$(id -u)/dev.herdr.server" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
sleep 2

# 9. herdr plugins
log "herdr plugins"
herdr plugin link "$HOME/.config/herdr/local-plugins/tab-numbers" >/dev/null 2>&1 || warn "tab-numbers: already linked or failed"
for p in "${HERDR_PLUGINS[@]}"; do
  if herdr plugin list 2>/dev/null | grep -q "github:$p@"; then continue; fi
  herdr plugin install "$p" --yes >/dev/null || warn "herdr plugin $p failed — retry: herdr plugin install $p --yes"
done
herdr config check || warn "herdr config check reported issues"

# 10. Claude config (private repo)
if [[ -x "$HOME/claude-config/apply.sh" ]]; then
  log "Applying claude-config"
  "$HOME/claude-config/apply.sh"
else
  warn "claude-config not found. After 'gh auth login':"
  warn "  gh repo clone sanketssc/claude-config ~/claude-config && ~/claude-config/apply.sh"
fi

cat <<'EOF'

Core setup done. Manual steps left:

  1. Tailscale:   sudo brew services start tailscale && tailscale up
  2. invok3r:     add a ~/.ssh/config Host block + key (ssh-keygen, ssh-copy-id), then
                  herdr machine add invok3r --label invok3r
  3. Collie:      join the crew led by invok3r as a new member
                    (on invok3r)  collie crew invite
                    (here)        collie link   # puts `collie` on PATH
                                  collie crew join https://<invok3r MagicDNS name> @<token-file> --address <this Mac's MagicDNS name>:8787 --label <name>
                                  set COLLIE_HOST=<this Mac's tailnet IP> in the collie .env, then collie restart
                    (on invok3r)  collie restart
  4. Claude:      run `claude`, /login, re-add MCP servers (see ~/claude-config/README.md)
  5. Nushell:     keep zsh as login shell; open nu from kitty/herdr instead:
                    kitty.conf:        shell /opt/homebrew/bin/nu
                    herdr config.toml: [terminal] default_shell = "/opt/homebrew/bin/nu"
                  nushell on macOS reads ~/Library/Application Support/nushell unless XDG_CONFIG_HOME is set.
                  prompt/tools: starship init nu · zoxide init nushell · atuin init nu
                  starship config lives at ~/.config/starship/starship.toml → set STARSHIP_CONFIG to it.
  6. Matiks repos: clone matiks-monorepo, matiks-client, matiks-skills-hub into ~/Documents/matiks, then
                  monorepo: `task tools:install` (mise pins go/lefthook/mockery/...), `task hooks:install`
                  client:   Node 22 (.nvmrc) → `mise use node@22` in the repo, `corepack enable`, `yarn`,
                            `cd ios && pod install`
                  shell rc: activate mise (zsh: eval "$(mise activate zsh)" · nu: see mise docs) and add ~/go/bin to PATH
                  re-run ~/claude-config/apply.sh after cloning matiks-skills-hub (company skill links)
  7. Xcode:       install from the App Store; Android SDK: open Android Studio once
  8. whoburnedmore: `npx whoburnedmore` (link this Mac), then `npx whoburnedmore install-sync`
EOF
