# Aliases
alias rw="railway"
alias vim="nvim"
alias refresh="source ~/.zshrc"
alias add="git add"
alias status="git status"
alias commit="git commit -m"
alias bisect="git bisect"
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
alias openzsh="nvim ~/.zshrc"
alias p="pnpm"
alias delete-mod="rm pnpm-lock.yaml && rm -rf node_modules/"
alias inngest="npx inngest-cli@latest dev"
alias !inngest="npx inngest-cli@latest dev"
alias remove-branches="git fetch --prune && git branch --merged | grep -v "\*" | xargs -r git branch -d"

# Shell config
eval "$(starship init zsh)"
source <(fzf --zsh)

# Rust
source "$HOME/.cargo/env"

# Completions

## Docker
fpath=(/Users/darrylbrooks/.docker/completions $fpath)
autoload -Uz compinit
compinit

## bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "/Users/darrylbrooks/.bun/_bun" ] && source "/Users/darrylbrooks/.bun/_bun"
zstyle ':completion:*' menu select

# Environment variables
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/darrylbrooks/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/darrylbrooks/.lmstudio/bin"

# mySQL client
export PATH="/opt/homebrew/opt/mysql-client@8.4/bin:$PATH"

# Node
export PATH="/opt/homebrew/opt/node@18/bin:$PATH"
export PATH="/opt/homebrew/opt/node@20/bin:$PATH"
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
