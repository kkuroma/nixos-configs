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

      shell-python     = "nix develop ~/Shells/python";
      shell-networking = "nix develop ~/Shells/networking";
    };

    extraConfig = ''
      $env.config.show_banner = false
      $env.config.edit_mode = "emacs"
    '';
  };
}
