{ pkgs, lib, ... }:
let
  # Base config — noctalia appends [palettes.noctalia] below this at runtime.
  # Use the activation sentinel pattern so the file stays writable for noctalia.
  configFile = pkgs.writeText "starship-base.toml" ''
    palette = "noctalia"
    format = "$shell$directory$git_branch$git_state$git_status$git_metrics$nix_shell$env_var$fill$cmd_duration $time$line_break$character"

    [shell]
    disabled = false
    bash_indicator = "bash "
    zsh_indicator = ""
    nu_indicator = "nu "
    format = "[$indicator]($style)"
    style = "cyan bold"

    [directory]
    style = "blue bold"
    truncation_length = 4
    truncate_to_repo = true
    read_only = " 󰌾"

    [git_branch]
    symbol = " "
    format = "[$symbol$branch]($style) "
    style = "bright-black"

    [git_status]
    format = '([$all_status$ahead_behind]($style) )'
    style = "cyan"

    [git_state]
    format = '\([$state( $progress_current/$progress_total)]($style)\) '
    style = "bright-black"

    [git_metrics]
    disabled = false

    [nix_shell]
    disabled = false
    heuristic = false
    impure_msg = "nix-dev"
    pure_msg = "nix-dev(pure)"
    unknown_msg = "nix-dev"
    format = "[$symbol$state]($style) "
    symbol = " "
    style = "bold blue"

    [env_var.DEV_SHELL]
    variable = "DEV_SHELL"
    format = "[$symbol$env_value]($style) "
    symbol = "󱠇 "
    style = "bold yellow"
    disabled = false

    [fill]
    symbol = " "

    [cmd_duration]
    format = "[$duration]($style)"
    style = "yellow"
    min_time = 1000

    [time]
    disabled = false
    style = "bold white"
    format = "[$time]($style)"
    time_format = "%H:%M:%S"

    [character]
    success_symbol = "[❯](bold green)"
    error_symbol = "[❯](bold red)"
    vicmd_symbol = "[❮](bold green)"
  '';
in
{
  home.packages = [ pkgs.starship ];

  # Write mutable starship.toml so noctalia can append its palette section.
  # Only re-copies when our nix config changes; noctalia's palette additions survive rebuilds.
  home.activation.starshipConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dest="$HOME/.config/starship.toml"
    sentinel="$HOME/.config/.starship-nix-src"
    mkdir -p "$(dirname "$dest")"
    if [ "$(cat "$sentinel" 2>/dev/null)" != "${configFile}" ]; then
      cp "${configFile}" "$dest"
      chmod u+w "$dest"
      printf '%s' "${configFile}" > "$sentinel"
    fi
  '';

  # Generate nushell init script at activation time.
  home.activation.starshipNushellInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.cache/starship"
    ${pkgs.starship}/bin/starship init nu > "$HOME/.cache/starship/init.nu"
  '';

  programs.zsh.initContent = ''
    eval "$(${pkgs.starship}/bin/starship init zsh)"
  '';

  programs.nushell.extraConfig = ''
    source ~/.cache/starship/init.nu
  '';
}
