{ pkgs, ... }:
{
  home.packages = with pkgs; [ lsd ];

  programs.nushell = {
    enable = true;

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
      grep    = "^grep --color=auto";
      fgrep   = "^fgrep --color=auto";
      egrep   = "^egrep --color=auto";
      diff    = "^diff --color=auto";
      ip      = "^ip --color=auto";
    };

    extraConfig = ''
      $env.config.show_banner = false
      $env.config.edit_mode = "emacs"

      $env.PROMPT_COMMAND = {||
        let dir = ($env.PWD | str replace $env.HOME "~")
        let dir_trimmed = if ($dir | str length) > 25 {
          "..." + ($dir | str substring (($dir | str length) - 22)..)
        } else {
          $dir
        }
        let venv = if "VIRTUAL_ENV" in $env {
          "[" + ($env.VIRTUAL_ENV | path basename) + "]-"
        } else {
          ""
        }
        let now = (date now | format date "%Y/%m/%d][%H:%M:%S")
        $"(ansi cyan)╭──($venv)[(ansi red)(ansi attr_bold)($env.USER)(ansi reset)(ansi cyan)@(ansi green)(ansi attr_bold)(sys host | get hostname)(ansi reset)(ansi cyan)][(ansi blue)(ansi attr_bold)($dir_trimmed)(ansi reset)(ansi cyan)]──[(ansi magenta)(ansi attr_bold)($now)(ansi reset)(ansi cyan)](ansi reset)(char newline)"
      }

      $env.PROMPT_COMMAND_RIGHT = {||
        if "CMD_DURATION_MS" in $env and ($env.CMD_DURATION_MS | into int) > 1000 {
          let ms = ($env.CMD_DURATION_MS | into int)
          let minutes = $ms // 60000
          let seconds = ($ms mod 60000) // 1000
          let millis = $ms mod 1000
          if $minutes > 0 {
            $" took ($minutes)m ($seconds)s"
          } else {
            $" took ($seconds).(($millis | fill --alignment right --width 3 --character '0'))s"
          }
        } else {
          ""
        }
      }

      $env.PROMPT_INDICATOR = {|| $"(ansi cyan)╰─(ansi green)(ansi attr_bold)>(ansi reset) " }
      $env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
      $env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
      $env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }
    '';
  };
}
