# zshrc for carapace's zsh bridge only. The bridge runs `zsh --no-rcs` and sources this file
# instead of ~/.config/zsh/.zshrc, so completion dirs must be added here: Homebrew formulae
# (scrcpy, mise, uv, ...) and Docker Desktop install their zsh completions in these.
fpath=(/opt/homebrew/share/zsh/site-functions $HOME/.docker/completions $fpath)
