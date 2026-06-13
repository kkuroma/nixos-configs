{ ... }:
{

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

      extern "init-shell" [
        --python          # Python tooling (uv, ruff, pyright) — packages via uv
        --cuda            # CUDA packages + LD_LIBRARY_PATH hook
        --npx             # Node.js / npx
        --networking      # Network/security tools
        --git             # git init + .gitignore + git in devShell
        --name: string    # Shell name shown in starship prompt
        --help(-h)        # Show help
      ]
    '';
  };
}
