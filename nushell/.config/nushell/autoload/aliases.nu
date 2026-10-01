# Aliases ported from zsh (.zshrc + the oh-my-zsh git plugin). Nushell loads this from its user
# autoload dir after config.nu, which keeps vim, lg, c, gs, gd, glog and tns.
# `help aliases` lists everything that is defined.

# git — from .zshrc
alias gt = git
alias ga = git add .
alias gc = git commit -m
# shadows coreutils' gpr (GNU pr), as it did in zsh. `--rebase=true` == `--rebase`, but carapace
# reads a bare `--rebase` as taking a value, which broke `gpr <TAB>` (remotes, branches, flags).
alias gpr = git pull --rebase=true
alias gP = git push
alias gco = git checkout
alias gcb = git checkout -b
alias gb = git branch

# git — oh-my-zsh names from shell history
alias gst = git status
alias gf = git fetch
alias gp = git push
alias gcp = git cherry-pick           # shadows coreutils' gcp (GNU cp), as it did in zsh
alias gl = git pull

# git — more oh-my-zsh staples
alias gaa = git add --all
alias gca = git commit --amend
alias gcan = git commit --amend --no-edit
alias gcam = git commit -am
alias gpf = git push --force-with-lease
alias gsw = git switch
alias gswc = git switch -c
alias gbd = git branch -d
alias gdca = git diff --cached
alias glo = git log --oneline --decorate -20
alias gm = git merge
alias grb = git rebase
alias grbc = git rebase --continue
alias grba = git rebase --abort
alias gsta = git stash push
alias gstp = git stash pop
alias gstl = git stash list
alias grs = git restore
alias grss = git restore --staged
alias gcl = git clone

# gcm: check out the repo's default branch (origin/HEAD, else main)
def gcm [] {
  let head = (git symbolic-ref --quiet --short refs/remotes/origin/HEAD | complete)
  let branch = if $head.exit_code == 0 { $head.stdout | str trim | str replace 'origin/' '' } else { 'main' }
  git checkout $branch
}

# gpsup: push the current branch and set its upstream
def gpsup [] { git push --set-upstream origin (git branch --show-current | str trim) }

# general
alias e = exit
alias v = nvim
alias y = yazi
alias t = task                        # go-task (matiks-monorepo Taskfile)
alias ll = ls -l
alias la = ls -a
alias nlof = fzf_listoldfiles.sh
alias nzo = zoxide_openfiles_nvim.sh

# mkcd: make a directory and cd into it
def --env mkcd [dir: path] { mkdir $dir; cd $dir }
