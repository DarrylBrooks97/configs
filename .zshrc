# Aliases
alias ll="ls"
alias compose="docker-compose"
alias rw="railway"
alias vim="nvim"
alias refresh="source ~/.zshrc"
alias newmac="brew bundle --file"
alias openzsh="nvim ~/.zshrc"
alias newssh="ssh-keygen -t rsa -b 4096 -C"
alias opentmux="nvim ~/.tmux.conf"
alias brewpath="/opt/homebrew/bin/brew"
alias oc="opencode"
alias ca="cursor-agent"
alias ld="lazydocker"
alias crit="critique"

# Git
alias add="git add"
alias st="git status"
alias commit="git commit -m"
alias add-tree='git worktree add'
alias list-tree='git worktree list'
alias remove-tree='git worktree remove'
alias bisect="git bisect"
alias pull="git pull"
alias push="git push"
alias ch="git checkout"
alias clone="git clone"
alias branch="git branch"
alias stash="git stash"
alias remote="git remote"
alias upstream="git push --set-upstream origin"
alias diff="git diff"
alias restore="git restore"
alias remove-branches="git fetch --prune && git branch --merged | grep -v "\*" | xargs -r git branch -d"
alias syncfork="git fetch upstream && git merge upstream/main && git push origin main"


# Code
alias p="pnpm"
alias c="claude --dangerously-skip-permissions"

# Docker commands
alias d="docker"
alias di="docker image"
alias dc="docker container"
alias dv="docker volume"

# K8s
alias kube="kubectl"
alias kp="kube get pods -o wide"
alias ks="kube get service -o wide"
alias kd="kube get deployments -o wide"


# Rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"


# Completions
autoload -Uz compinit
compinit -u

# Misc 
export CLAUDE_CODE_NO_FLICKER=1

## bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "/Users/darrylbrooks/.bun/_bun" ] && source "/Users/darrylbrooks/.bun/_bun"
# zstyle ':completion:*' menu select

# Environment variables
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

export PATH="/opt/homebrew/opt/node@22/bin:$PATH"

# pnpm
# export PNPM_HOME="/Users/darrylbrooks/Library/pnpm"
export PNPM_HOME="~/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/darrylbrooks/.lmstudio/bin"

# mySQL client
export PATH="/opt/homebrew/opt/mysql-client@8.4/bin:$PATH"

# Node
export PATH="/opt/homebrew/opt/node@20/bin:$PATH"
export PATH="/opt/homebrew/opt/node@22/bin:$PATH"
export PATH="/opt/homebrew/bin/cst_lsp:$PATH"

# bun completions
export PATH="$HOME/.local/bin:$PATH"

# Shell config
eval "$(starship init zsh)"
source <(fzf --zsh)

[ -s "/Users/dbrooks/.bun/_bun" ] && source "/Users/dbrooks/.bun/_bun"

# shellcheck shell=bash

# =============================================================================
#
# Utility functions for zoxide.
#

# pwd based on the value of _ZO_RESOLVE_SYMLINKS.
function __zoxide_pwd() {
    \builtin pwd -L
}

# cd + custom logic based on the value of _ZO_ECHO.
function __zoxide_cd() {
    # shellcheck disable=SC2164
    \builtin cd -- "$@" && __zoxide_pwd
}

# =============================================================================
#
# Hook configuration for zoxide.
#

# Hook to add new entries to the database.
function __zoxide_hook() {
    # shellcheck disable=SC2312
    \command zoxide add -- "$(__zoxide_pwd)"
}

# Initialize hook.
#
\builtin typeset -ga precmd_functions
\builtin typeset -ga chpwd_functions
# shellcheck disable=SC2034,SC2296
precmd_functions=("${(@)precmd_functions:#__zoxide_hook}")
# shellcheck disable=SC2034,SC2296
chpwd_functions=("${(@)chpwd_functions:#__zoxide_hook}")
chpwd_functions+=(__zoxide_hook)

# Report common issues.
function __zoxide_doctor() {
    [[ ${_ZO_DOCTOR:-1} -ne 0 ]] || return 0
    [[ ${chpwd_functions[(Ie)__zoxide_hook]:-} -eq 0 ]] || return 0

    _ZO_DOCTOR=0
    \builtin printf '%s\n' \
        'zoxide: detected a possible configuration issue.' \
        'Please ensure that zoxide is initialized right at the end of your shell configuration file (usually ~/.zshrc).' \
        '' \
        'If the issue persists, consider filing an issue at:' \
        'https://github.com/ajeetdsouza/zoxide/issues' \
        '' \
        'Disable this message by setting _ZO_DOCTOR=0.' \
        '' >&2
}

# =============================================================================
#
# When using zoxide with --no-cmd, alias these internal functions as desired.
#

# Jump to a directory using only keywords.
function __zoxide_z() {
    __zoxide_doctor
    if [[ "$#" -eq 0 ]]; then
        __zoxide_cd ~
    elif [[ "$#" -eq 1 ]] && { [[ -d "$1" ]] || [[ "$1" = '-' ]] || [[ "$1" =~ ^[-+][0-9]$ ]]; }; then
        __zoxide_cd "$1"
    elif [[ "$#" -eq 2 ]] && [[ "$1" = "--" ]]; then
        __zoxide_cd "$2"
    else
        \builtin local result
        # shellcheck disable=SC2312
        result="$(\command zoxide query --exclude "$(__zoxide_pwd)" -- "$@")" && __zoxide_cd "${result}"
    fi
}

# Jump to a directory using interactive search.
function __zoxide_zi() {
    __zoxide_doctor
    \builtin local result
    result="$(\command zoxide query --interactive -- "$@")" && __zoxide_cd "${result}"
}

# =============================================================================
#
# Commands for zoxide. Disable these using --no-cmd.
#

function cd() {
    __zoxide_z "$@"
}

function cdi() {
    __zoxide_zi "$@"
}

# Completions.
if [[ -o zle ]]; then
    __zoxide_result=''

    function __zoxide_z_complete() {
        # Only show completions when the cursor is at the end of the line.
        # shellcheck disable=SC2154
        [[ "${#words[@]}" -eq "${CURRENT}" ]] || return 0

        if [[ "${#words[@]}" -eq 2 ]]; then
            # Show completions for local directories.
            _cd -/

        elif [[ "${words[-1]}" == '' ]]; then
            # Show completions for Space-Tab.
            # shellcheck disable=SC2086
            __zoxide_result="$(\command zoxide query --exclude "$(__zoxide_pwd || \builtin true)" --interactive -- ${words[2,-1]})" || __zoxide_result=''

            # Set a result to ensure completion doesn't re-run
            compadd -Q ""

            # Bind '\e[0n' to helper function.
            \builtin bindkey '\e[0n' '__zoxide_z_complete_helper'
            # Sends query device status code, which results in a '\e[0n' being sent to console input.
            \builtin printf '\e[5n'

            # Report that the completion was successful, so that we don't fall back
            # to another completion function.
            return 0
        fi
    }

    function __zoxide_z_complete_helper() {
        if [[ -n "${__zoxide_result}" ]]; then
            # shellcheck disable=SC2034,SC2296
            BUFFER="cd ${(q-)__zoxide_result}"
            __zoxide_result=''
            \builtin zle reset-prompt
            \builtin zle accept-line
        else
            \builtin zle reset-prompt
        fi
    }
    \builtin zle -N __zoxide_z_complete_helper

    [[ "${+functions[compdef]}" -ne 0 ]] && \compdef __zoxide_z_complete cd
fi

eval "$(zoxide init zsh)"

# Entire CLI shell completion
autoload -Uz compinit && compinit -u && source <(entire completion zsh)
