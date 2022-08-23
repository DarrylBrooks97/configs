# Aliases
alias add="git add"
alias status="git status"
alias reload="source ~/.zshrc"
alias commit="git commit -m"
alias pull="git pull"
alias push="git push"
alias checkout="git checkout"
alias clone="git clone"
alias branch="git branch"
alias stash="git stash"
alias remote="git remote"
alias upstream="git push --set-upstream origin"
alias diff="git diff"
alias restore="git restore"
alias newssh="ssh-keygen -t rsa -b 4096 -C "
alias newmac="brew bundle --file"
alias showhidden="ls -ld .?*"

#plugins=(git,hypercwd)
eval "$(starship init zsh)"

export PATH="$PATH:/Users/darrylbrooks/Downloads/flutter/bin"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
