{ pkgs, lib, ... }:
let
  # U+E0B6 = left rounded powerline cap (blob open)
  # U+E0B4 = right rounded powerline cap (blob close)
  BL = builtins.fromJSON ''""'';
  BR = builtins.fromJSON ''""'';

  # Helper: wrap content in a noctalia-colored powerline pill
  blob = bg: fg: content: "[${BL}](fg:${bg})[${content}](fg:${fg} bg:${bg})[${BR}](fg:${bg})";

  # Colors use noctalia palette names which resolve to theme hex values
  starshipConfig = {
    format = "$shell$container$directory$git_branch$git_state$git_status$git_metrics$nix_shell$env_var$fill$cmd_duration$time$line_break$character";

    shell = {
      disabled = false;
      bash_indicator = "bash";
      zsh_indicator = "";
      nu_indicator = "nu";
      format = "[$indicator]($style) ";
      style = "bold cyan";
    };

    container = {
      disabled = false;
      symbol = "󰆧";
      format = "${blob "green" "black" "$symbol $name"} ";
      style = "fg:black bg:green";
    };

    directory = {
      style = "fg:black bg:blue";
      format = "${blob "blue" "black" "$path$read_only"} ";
      truncation_length = 4;
      truncate_to_repo = true;
      read_only = "󰌾";
    };

    git_branch = {
      symbol = " ";
      format = "${blob "maroon" "black" "$symbol$branch"} ";
      style = "fg:text bg:maroon";
    };

    git_status = {
      format = "([$all_status$ahead_behind](fg:cyan) )";
      style = "fg:cyan";
    };

    git_state = {
      format = "\\([$state( $progress_current/$progress_total)](fg:overlay2)\\) ";
      style = "fg:overlay2";
    };

    git_metrics.disabled = false;

    nix_shell = {
      disabled = false;
      heuristic = false;
      impure_msg = "dev";
      pure_msg = "dev-pure";
      unknown_msg = "nix-dev";
      format = "${blob "sky" "black" "$symbol$state"} ";
      symbol = "󱄅 ";
      style = "fg:black bg:sky";
    };

    env_var.DEV_SHELL = {
      variable = "DEV_SHELL";
      format = "${blob "yellow" "black" "$symbol$env_value"} ";
      symbol = "󱠇 ";
      style = "fg:black bg:yellow";
      disabled = false;
    };

    fill.symbol = " ";

    cmd_duration = {
      format = "${blob "peach" "black" "$duration"}";
      style = "fg:black bg:peach";
      min_time = 1000;
    };

    time = {
      disabled = false;
      style = "fg:black bg:mauve";
      format = " ${blob "mauve" "black" "$time"}";
      time_format = "%H:%M:%S";
    };

    character = {
      success_symbol = "[❯](bold green)";
      error_symbol = "[❯](bold red)";
      vicmd_symbol = "[❮](bold green)";
    };
  };

  configFile = (pkgs.formats.toml { }).generate "starship-base.toml" starshipConfig;
in
{
  home.packages = [ pkgs.starship ];

  # Write mutable starship.toml so noctalia can update its palette section
  # Noctalia uses "# >>> NOCTALIA STARSHIP PALETTE >>>" as a marker: it preserves everything before the marker and rewrites from the marker onward with the current palette
  # We must keep our base config before that marker
  home.activation.starshipConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dest="$HOME/.config/starship.toml"
    sentinel="$HOME/.config/.starship-nix-src"
    marker="# >>> NOCTALIA STARSHIP PALETTE >>>"
    mkdir -p "$(dirname "$dest")"
    if [ "$(cat "$sentinel" 2>/dev/null)" != "${configFile}" ]; then
      # Preserve noctalia's palette block if already written
      noctalia_tail=$(sed -n "/^$marker/,\$p" "$dest" 2>/dev/null || true)
      if [ -n "$noctalia_tail" ]; then
        { printf 'palette = "noctalia"\n'; cat "${configFile}"; printf '\n'; printf '%s\n' "$noctalia_tail"; } > "$dest"
      else
        # Plant the marker so noctalia updates in-place instead of replacing the file
        { printf 'palette = "noctalia"\n'; cat "${configFile}"; printf '\n%s\n' "$marker"; } > "$dest"
      fi
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
