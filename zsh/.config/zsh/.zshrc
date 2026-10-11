ZSH_THEME="half-life" # set by `omz`

# export PATH=$HOME/bin:/usr/local/bin:$PATH
# echo source ~/.bash_profile

# load env vars from .zprofile into the shells (ZDOTDIR on the XDG layout, ~ otherwise)
[[ -f ${ZDOTDIR:-$HOME}/.zprofile ]] && source ${ZDOTDIR:-$HOME}/.zprofile

command -v brew >/dev/null && eval "$(brew shellenv)"
# source .zprofile in all zsh shells (just in case)
# [[ -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile"

# zsh stays the login shell (scripts, `ssh host cmd` and T3's server need a POSIX shell), but the
# shells you type in are nushell. Hand two kinds of interactive zsh to nu:
# - SSH logins (SSH_TTY is set only when ssh gives the session a terminal).
# - T3 Code terminals: T3 starts $SHELL and has no setting for it. Its setup actions run with
#   NO_COLOR=1 and type POSIX commands into the terminal, so they stay in zsh.
# ZSH_TO_NU stops a `zsh` started from that nu from jumping back into nu.
if [[ -o interactive && -z $ZSH_TO_NU ]] && { [[ -n $SSH_TTY ]] || [[ -n $T3CODE_PROJECT_ROOT && -z $NO_COLOR ]]; } && command -v nu >/dev/null; then
    export ZSH_TO_NU=1
    if [[ -o login ]]; then exec nu --login; else exec nu; fi
fi

if command -v gdircolors >/dev/null; then eval "$(gdircolors)"
elif command -v dircolors >/dev/null; then eval "$(dircolors)"; fi

# zsh plugins come from Homebrew (macOS) or pacman (Arch: /usr/share/zsh/plugins)
_source_zsh_plugin() {
    local d
    for d in ${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/share} /usr/share/zsh/plugins; do
        [[ -f $d/$1/$1.zsh ]] && { source "$d/$1/$1.zsh"; return; }
    done
}

# zsh plugins
plugins=(
    git 
    ## with oh-my-zsh and not homebrew
     zsh-autosuggestions 
    zsh-syntax-highlighting
    web-search
)

# Update Expo IP and generate QR code
update_expo_ip() {
    # ---------------------------------------------------------
    # 📝 EDIT THIS PATH: Point this to your project's .env file
    # ---------------------------------------------------------
    local env_file="$HOME/Documents/matiks/matiks-client/.env"

    # 1. Detect the local IP address
    local ip=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ip=$(ipconfig getifaddr en0) # macOS Wi-Fi
    else
        ip=$(hostname -I | awk '{print $1}') # Linux
    fi

    # Fixed: Added the space between 'if' and '['
    if [ -z "$ip" ]; then
        echo "❌ Could not find IP address."
        return 1
    fi

    echo "📡 Detected Local IP: $ip"

    # 2. Update the first line of the .env file
    if [ -f "$env_file" ]; then
        # Grab whatever variable name is before the '=' on the very first line
        local var_name=$(head -n 1 "$env_file" | cut -d '=' -f 1)
        
        # Replace the first line with the new IP
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "1s/.*/$var_name=$ip/" "$env_file"
        else
            sed -i "1s/.*/$var_name=$ip/" "$env_file"
        fi
        
        echo "✅ Updated $env_file (Line 1): $var_name=$ip"
    else
        echo "⚠️ .env file not found at: $env_file"
        echo "Please update the 'env_file' variable in your ~/.zshrc"
        return 1
    fi

    # 3. Construct custom URL (URL-encoding the inner http://IP:8081)
    local expo_uri="exp+matiks://expo-development-client/?url=http%3A%2F%2F${ip}%3A8081"

    # 4. Generate the QR code in the terminal
    echo -e "\n📱 Scan this QR code:\n"
    # Use white background + black text to ensure QR is visible in any terminal theme
    curl -s -d "$expo_uri" https://qrcode.show
    echo -e "\n🔗 URI: $expo_uri\n"
}

# XDG layout (new Mac: /etc/zshenv sets XDG_*): keep history + completion dumps out of ~
if [[ -n $XDG_STATE_HOME ]]; then
    mkdir -p "$XDG_STATE_HOME/zsh" "$XDG_CACHE_HOME/zsh"
    HISTFILE="$XDG_STATE_HOME/zsh/history"
    ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
fi

if [[ -f $ZSH/oh-my-zsh.sh ]]; then
    source $ZSH/oh-my-zsh.sh
else
    # no oh-my-zsh (new Mac): plain completion + history
    autoload -Uz compinit && compinit -d "${ZSH_COMPDUMP:-$HOME/.zcompdump}"
    HISTSIZE=50000 SAVEHIST=50000
    setopt share_history hist_ignore_dups
    _source_zsh_plugin zsh-autosuggestions
fi

# unbind ctrl g in terminal
bindkey -r "^G"

# Starship 
bindkey -v
if [[ "${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select" || \
      "${widgets[zle-keymap-select]#user:}" == "starship_zle-keymap-select-wrapped" ]]; then
    zle -N zle-keymap-select "";
fi
eval "$(starship init zsh)"

# Zoxide
eval "$(zoxide init zsh)"

# FZF
eval "$(fzf --zsh)"

# FZF with Git right in the shell by Junegunn : check out his github below
# Keymaps for this is available at https://github.com/junegunn/fzf-git.sh
# personal scripts live in ~/scripts (old layout) or ~/.local/bin (XDG layout); both are on PATH
for _d in "$HOME/scripts" "$HOME/.local/bin"; do
    [[ -f $_d/fzf-git.sh ]] && { source "$_d/fzf-git.sh"; break; }
done
unset _d

# Atuin Configs
export ATUIN_NOBIND="true"
eval "$(atuin init zsh)"
# bindkey '^r' _atuin_search_widget
bindkey '^r' atuin-up-search-viins
#User configuration
# export MANPATH="/usr/local/man:$MANPATH"

#----- Vim Editing modes & keymaps ------ 
set -o vi

export EDITOR=nvim
export VISUAL=nvim

bindkey -M viins '^E' autosuggest-accept
bindkey -M viins '^P' up-line-or-history
bindkey -M viins '^N' down-line-or-history
#----------------------------------------

# -------------------ALIAS----------------------
# These alias need to have the same exact space as written here
# HACK: For Running Go Server using Air
alias air='$(go env GOPATH)/bin/air'

# other Aliases shortcuts
alias c="clear"
alias e="exit"
alias vim="nvim"
alias cd='z'

# Tmux 
alias tmux="tmux -f $TMUX_CONF"
alias a="attach"
# calls the tmux new session script
alias tns="tmux-sessionizer"

# fzf 
# personal scripts (on PATH)
alias nlof="fzf_listoldfiles.sh"
# opens documentation through fzf (eg: git,zsh etc.)
alias fman="compgen -c | fzf | xargs man"

# zoxide (script on PATH)
alias nzo="zoxide_openfiles_nvim.sh"

# Next level of an ls 
# options :  --no-filesize --no-time --no-permissions 
alias ls="eza --long --color=always --icons=always --no-user" 

# tree
alias tree="tree -L 3 -a -I '.git' --charset X "
alias dtree="tree -L 3 -a -d -I '.git' --charset X "

# lstr
alias lstr="lstr --icons"

# git aliases
alias gt="git"
alias ga="git add ."
alias gs="git status -s"
alias gc='git commit -m'
alias gpr='git pull --rebase'
alias gP='git push'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gd='git diff'
alias glog='git log --oneline --graph --all'
alias gh-create='gh repo create --private --source=. --remote=origin && git push -u --all && gh browse'

alias nvim-scratch="NVIM_APPNAME=nvim-scratch nvim"

# lazygit
alias lg="lazygit"

# mpd start alias
alias mpds="mpd ~/.config/mpd/mpd.conf"

# obsidian icloud path
alias sethvault="cd ~/Library/Mobile\ Documents/iCloud~md~obsidian/Documents/sethVault/"

# matiks dev tmux launcher
# (company scripts: kept out of the public repo, only present in ~/scripts on machines that have them)
alias ss="matiks-dev.sh"
alias sss="matiks-dev.sh sync"
alias ssa="matiks-dev-analytics.sh"
alias sssa="matiks-dev-analytics.sh sync"
# ---------------------------------------

# brew installations activation (new mac systems brew path: opt/homebrew , not usr/local )
# source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
_source_zsh_plugin zsh-syntax-highlighting

# . "/Users/personal/.deno/env"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# bun completions
[ -s "${BUN_INSTALL:-$HOME/.bun}/_bun" ] && source "${BUN_INSTALL:-$HOME/.bun}/_bun"
# Android tools on PATH (ANDROID_HOME / JAVA_HOME come from .zshenv)
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator


# mise (new Mac: Go/Node pins per repo); no-op where mise is not installed
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

# Created by `pipx` on 2026-04-21 11:48:45
export PATH="$PATH:$HOME/.local/bin"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
(( ${+_comps[docker]} )) || compinit
# End of Docker CLI completions
