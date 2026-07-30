{ pkgs, inputs, ... }:
# This file contains code we own and custom shell scripts that can be injected as shell commands
let
  # Inject nixpkgs versions to the init shell script to avoid version drife
  initShell = pkgs.writeShellScriptBin "init-shell" (
    builtins.replaceStrings [ "@NIXPKGS_REV@" ] [ inputs.nixpkgs.rev ]
      (builtins.readFile ./init-shell.sh)
  );

  # shell scripts
  compressMkv = pkgs.writeShellScriptBin "compress-mkv"
    (builtins.readFile ./compress-mkv.sh);

  upscaleMkv = pkgs.writeShellScriptBin "upscale-mkv"
    (builtins.readFile ./upscale-mkv.sh);
  
  colorPicker = pkgs.writeShellScriptBin "color-picker"
    (builtins.readFile ./color-picker.sh);

  # fd -> fzf files inside a given directory (home) and launches selected file in vscodium
  codeLauncher = pkgs.writeShellScriptBin "code-launcher" ''
    path=$(${pkgs.fd}/bin/fd -H -E .git -t f -t d . ~/ \
      | ${pkgs.fzf}/bin/fzf \
          --pointer="" \
          --marker="" \
          --prompt="Open in VSCode: " \
          --height=100% \
          --reverse \
          --preview="${pkgs.bat}/bin/bat --color=always --style=numbers {}" \
          --preview-window=right:50%:wrap \
          --color=fg:7,bg:-1,hl:4,fg+:7,bg+:-1,hl+:4,info:2,prompt:4,pointer:3,marker:7,spinner:7,header:4)
    if [ -n "$path" ]; then
      nohup ${pkgs.vscodium}/bin/codium --ozone-platform=wayland "$path" > /dev/null 2>&1 &
      ${pkgs.libnotify}/bin/notify-send -a "System" "Code launcher" "Launched VSCode: $path" -i preferences-desktop
    fi
  '';

  # code launcher, but for dolphin
  fileLauncher = pkgs.writeShellScriptBin "file-launcher" ''
    # -t d restricts fd to directories only
    # --max-depth can be added if ~/ is too slow
    path=$(${pkgs.fd}/bin/fd -H -E .git -t d . ~/ \
      | ${pkgs.fzf}/bin/fzf \
          --pointer="▶" \
          --marker="" \
          --prompt="Open Folder: " \
          --height=100% \
          --reverse \
          --preview="${pkgs.lsd}/bin/lsd --tree --depth 2 --color always {}" \
          --preview-window=right:50%:wrap \
          --color=fg:7,bg:-1,hl:4,fg+:7,bg+:-1,hl+:4,info:2,prompt:4,pointer:3,marker:7,spinner:7,header:4)

    if [ -n "$path" ]; then
      # Use setsid or disown to ensure the process survives the terminal closing
      setsid ${pkgs.kdePackages.dolphin}/bin/dolphin "$path" > /dev/null 2>&1 &
      ${pkgs.libnotify}/bin/notify-send -a "System" "File Browser" "Opening: $path" -i folder-open
    fi
  '';
in
{
  home.packages = [ initShell compressMkv upscaleMkv colorPicker codeLauncher fileLauncher ];
}
