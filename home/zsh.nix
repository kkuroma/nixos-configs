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

      shell-python     = "nix develop ~/Shells/python";
      shell-networking = "nix develop ~/Shells/networking";
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
