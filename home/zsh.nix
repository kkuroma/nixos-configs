{ lib, pkgs, ... }:
{
  home.packages = with pkgs; [ lsd ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    defaultKeymap = "emacs";

    completionInit = "autoload -U compinit && compinit -d ~/.cache/zcompdump";

    history = {
      size = 1000;
      save = 2000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
    };

    shellAliases = {
      ".."    = "cd ..";
      "..."   = "cd ../..";
      "...."  = "cd ../../..";
      "....." = "cd ../../../..";
      dl      = "cd ~/Downloads";
      doc     = "cd ~/Documents";
      dt      = "cd ~/Desktop";
      g       = "git";
      snvim   = "sudo nvim";
      ls      = "lsd --color=auto";
      ll      = "lsd -l";
      la      = "lsd -A";
      lah     = "lsd -lah";
      l       = "lsd -CF";
      grep    = "grep --color=auto";
      fgrep   = "fgrep --color=auto";
      egrep   = "egrep --color=auto";
      diff    = "diff --color=auto";
      ip      = "ip --color=auto";
      history = "history 0";
      reload  = "exec zsh";
    };

    initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=blue'
      '')
      ''
        setopt autocd interactivecomments magicequalsubst nonomatch notify numericglobsort promptsubst
        WORDCHARS=''${WORDCHARS//\/}
        PROMPT_EOL_MARK=""
        TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'
        VIRTUAL_ENV_DISABLE_PROMPT=1

        eval "$(dircolors -b)"
        export LS_COLORS="$LS_COLORS:ow=30;44:"
        export LESS_TERMCAP_mb=$'\E[1;31m'
        export LESS_TERMCAP_md=$'\E[1;36m'
        export LESS_TERMCAP_me=$'\E[0m'
        export LESS_TERMCAP_so=$'\E[01;33m'
        export LESS_TERMCAP_se=$'\E[0m'
        export LESS_TERMCAP_us=$'\E[1;32m'
        export LESS_TERMCAP_ue=$'\E[0m'

        zstyle ':completion:*:*:*:*:*' menu select
        zstyle ':completion:*' auto-description 'specify: %d'
        zstyle ':completion:*' completer _expand _complete
        zstyle ':completion:*' format 'Completing %d'
        zstyle ':completion:*' group-name ""
        zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
        zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or the character to insert%s'
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*' rehash true
        zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
        zstyle ':completion:*' verbose true
        zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
        zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

        bindkey ' ' magic-space
        bindkey '^U' backward-kill-line
        bindkey '^[[3;5~' kill-word
        bindkey '^[[3~' delete-char
        bindkey '^[[1;5C' forward-word
        bindkey '^[[1;5D' backward-word
        bindkey '^[[5~' beginning-of-buffer-or-history
        bindkey '^[[6~' end-of-buffer-or-history
        bindkey '^[[H' beginning-of-line
        bindkey '^[[F' end-of-line
        bindkey '^[[Z' undo
        bindkey '^F' autosuggest-accept

        preexec() {
            timer=$(($(date +%s%N)/1000000))
        }

        precmd() {
            local return_code=$?

            if [ -n "$timer" ]; then
                local now=$(($(date +%s%N)/1000000))
                local elapsed=$(($now-$timer))

                local minutes=$((elapsed / 60000))
                local seconds=$(((elapsed % 60000) / 1000))
                local ms=$((elapsed % 1000))

                if [ $return_code -eq 0 ]; then
                    local code_color="\033[32m"
                else
                    local code_color="\033[31m"
                fi

                if [ $elapsed -gt 1000 ]; then
                    if [ $minutes -gt 0 ]; then
                        print -P "\033[34m󰁔\033[0m ''${code_color}''${return_code}\033[0m took ''${minutes}m ''${seconds}s"
                    else
                        print -P "\033[34m󰁔\033[0m ''${code_color}''${return_code}\033[0m took ''${seconds}.$(printf "%03d" $ms)s"
                    fi
                fi

                unset timer
            fi

            print ""
        }

        PROMPT=$'%F{cyan}╭──''${VIRTUAL_ENV:+[$(basename $VIRTUAL_ENV)]─}[%B%F{red}%n%b%F{yellow}@%B%F{green}%m%b%F{cyan}][%B%F{blue}%25<…<%~%<<%b%F{cyan}]──[%B%F{magenta}%D{%Y/%m/%d}%b%F{cyan}][%B%F{yellow}%D{%H:%M:%S}%b%F{cyan}]\n%F{cyan}╰─%B%(#.%F{red}#.%F{green}▶)%b%F{reset} '
        RPROMPT=""

        export NVM_DIR="$HOME/.config/nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

        [[ -f "$HOME/.config/.dart-cli-completion/zsh-config.zsh" ]] && \
          . "$HOME/.config/.dart-cli-completion/zsh-config.zsh"
      ''
    ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };
}
