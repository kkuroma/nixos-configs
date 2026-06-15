# ── Homebrew ────────────────────────────────────────────────────────────────
[[ -d /opt/homebrew/bin ]] && export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# ── Completion ───────────────────────────────────────────────────────────────
autoload -U compinit && compinit -d ~/.cache/zcompdump

zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or the character to insert%s'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' rehash true
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
zstyle ':completion:*' verbose true
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

# ── Options ──────────────────────────────────────────────────────────────────
setopt autocd interactivecomments magicequalsubst nonomatch notify numericglobsort promptsubst
WORDCHARS=${WORDCHARS//\/}
PROMPT_EOL_MARK=''
TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'
VIRTUAL_ENV_DISABLE_PROMPT=1
defaultKeymap=emacs

# ── History ──────────────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=1000
SAVEHIST=2000
setopt hist_ignore_dups hist_ignore_space hist_expire_dups_first

# ── Keybindings ──────────────────────────────────────────────────────────────
bindkey -e
bindkey ' '        magic-space
bindkey '^U'       backward-kill-line
bindkey '^[[3;5~'  kill-word
bindkey '^[[3~'    delete-char
bindkey '^[[1;5C'  forward-word
bindkey '^[[1;5D'  backward-word
bindkey '^[[5~'    beginning-of-buffer-or-history
bindkey '^[[6~'    end-of-buffer-or-history
bindkey '^[[H'     beginning-of-line
bindkey '^[[F'     end-of-line
bindkey '^[[Z'     undo
bindkey '^F'       autosuggest-accept

# ── Aliases ──────────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias dl='cd ~/Downloads'
alias doc='cd ~/Documents'
alias dt='cd ~/Desktop'
alias g='git'
alias ls='lsd --color=auto'
alias ll='lsd -l'
alias la='lsd -A'
alias lah='lsd -lah'
alias l='lsd -CF'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias history='history 0'
alias reload='exec zsh'

# ── LESS colours ─────────────────────────────────────────────────────────────
export LESS_TERMCAP_mb=$'\E[1;31m'
export LESS_TERMCAP_md=$'\E[1;36m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;33m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_us=$'\E[1;32m'
export LESS_TERMCAP_ue=$'\E[0m'

# ── Plugins (install via: brew install zsh-autosuggestions zsh-syntax-highlighting zoxide lsd) ──
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=blue'
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# ── NVM ──────────────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# ── Dart ─────────────────────────────────────────────────────────────────────
[[ -f "$HOME/.config/.dart-cli-completion/zsh-config.zsh" ]] && \
  . "$HOME/.config/.dart-cli-completion/zsh-config.zsh"

# ── Prompt ───────────────────────────────────────────────────────────────────
preexec() {
  _prompt_timer=$(($(date +%s%N)/1000000))
}

precmd() {
  local rc=$?
  if [[ -n "$_prompt_timer" ]]; then
    local now=$(($(date +%s%N)/1000000))
    local elapsed=$(( now - _prompt_timer ))
    local minutes=$(( elapsed / 60000 ))
    local seconds=$(( (elapsed % 60000) / 1000 ))
    local ms=$(( elapsed % 1000 ))
    local code_color=$( [[ $rc -eq 0 ]] && echo "\033[32m" || echo "\033[31m" )
    if (( elapsed > 1000 )); then
      if (( minutes > 0 )); then
        print -P "\033[34m󰁔\033[0m ${code_color}${rc}\033[0m took ${minutes}m ${seconds}s"
      else
        print -P "\033[34m󰁔\033[0m ${code_color}${rc}\033[0m took ${seconds}.$(printf "%03d" $ms)s"
      fi
    fi
    unset _prompt_timer
  fi
  print ''
}

PROMPT=$'%F{cyan}╭──${VIRTUAL_ENV:+[$(basename $VIRTUAL_ENV)─]}[%B%F{red}%n%b%F{yellow}@%B%F{green}%m%b%F{cyan}][%B%F{blue}%25<…<%~%<<%b%F{cyan}]──[%B%F{magenta}%D{%Y/%m/%d}%b%F{cyan}][%B%F{yellow}%D{%H:%M:%S}%b%F{cyan}]\n%F{cyan}╰─%B%(#.%F{red}#.%F{green}▶)%b%F{reset} '
RPROMPT=''
