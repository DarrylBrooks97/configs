export PATH="~/.npm-packages/bin:${PATH}"
ZSH_THEME="robbyrussell"

# Uncomment the following line to automatically update without prompting.
DISABLE_UPDATE_PROMPT="true"

# Aliases
alias add="git add"
alias status="git status"
alias reload="source ~/.zshrc"
alias commit="git commit -m"
alias pull="git pull"
alias push="git push"
alias checkout="git checkout"
alias which="which -A"
alias clone="git clone"
alias branch="git branch"
alias stash="git stash"
alias remote="git remote"
alias upstream="git push --set-upstream origin"

eval "$(starship init zsh)"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/darrylb/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/darrylb/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/darrylb/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/darrylb/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
