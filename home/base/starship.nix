{ pkgs, lib, osConfig, ... }:
# One starship prompt for every host: two powerline islands (zsh/path/git/tools left duration/time/host right) over two lines, colored bg + black text.

let
  # Nerd Font glyphs as ASCII JSON escapes, never write NF icons literally in Nix strings.
  g = builtins.fromJSON;
  capL     = g ''""'';   # left rounded island cap
  capR     = g ''""'';   # right rounded island cap
  slant    = g ''""'';   # solid slant (seamless slanted seam between blobs)
  pythonIc = g ''""'';   # nf-dev-python
  cubeIc   = g ''"󰆧"'';   # nf-md-cube_outline (container)
  lockIc   = g ''"󰌾"'';   # nf-md-lock (read-only dir)
  branchIc = g ''"󰊢"'';   # nf-dev-git_branch
  shellIc  = g ''"󱠇"'';   # nf-md-list_status (dev shell)
  clockIc  = g ''""'';   # clock (time)
  timerIc  = g ''"󱎫"'';   # stopwatch (cmd duration)
  folder   = g ''""'';   # folder (dir truncation)
  promptR  = g ''"❯"'';   # heavy right angle bracket
  promptL  = g ''"❮"'';   # heavy left angle bracket

  dirIcons = builtins.fromJSON ''{"Documents": "󰈙 ", "Downloads": " ", "Music": "󰝚 ", "Pictures": " "}'';
  open  = color: "[${capL}](fg:${color})";
  close = color: "[${capR}](fg:${color})";
  seam  = prev: next: "[${slant}](fg:${prev} bg:${next})";
  slot  = color: content: "[${content}](fg:black bg:${color})";

  starshipConfig = {
    format = lib.concatStrings [
      (open "overlay1") "$shell" (seam "overlay1" "lavender") "$directory" (seam "lavender" "peach")
      "$git_branch" (close "peach")
      "$git_status$git_metrics$python$env_var$container$git_state$fill"
      (open "teal") "$cmd_duration" (seam "teal" "yellow") "$time" (seam "yellow" "overlay1")
      "$hostname" (close "overlay1")
      "$line_break$character"
    ];

    shell = {
      disabled = false;
      bash_indicator = "bash";
      zsh_indicator = "zsh";
      nu_indicator = "nu";
      format = slot "overlay1" "$indicator";
    };

    directory = {
      format = slot "lavender" "$read_only$path";
      truncation_length = 3;
      truncation_symbol = "${folder} ";
      truncate_to_repo = true;
      read_only = "${lockIc} ";
      substitutions = dirIcons;
    };

    git_branch = {
      symbol = "${branchIc} ";
      format = slot "peach" "$symbol$branch";
    };

    # after the island: git status/metrics float (no bg), then the tool blobs
    git_status = {
      format = "( [$all_status$ahead_behind]($style))";
      style = "fg:peach";
    };

    # tools merge into one island like the front
    python = {
      symbol = pythonIc;
      format = "( ${open "red"}${slot "red" "$symbol $virtualenv"})";
      detect_files = [];
      detect_extensions = [];
      detect_folders = [];
    };

    env_var.DEV_SHELL = {
      disabled = false;
      variable = "DEV_SHELL";
      symbol = "${shellIc} ";
      format = "(${seam "red" "blue"}${slot "blue" "$symbol$env_value"}${close "blue"})";
    };

    container = {
      disabled = false;
      symbol = cubeIc;
      format = "(${seam "red" "blue"}${slot "blue" "$symbol $name"}${close "blue"})";
    };

    git_state = {
      format = "\\([$state( progress_current/$progress_total)](fg:overlay2)\\) ";
      style = "fg:overlay2";
    };

    git_metrics = {
      disabled = false;
      format = "( [+$added](fg:green))( [-$deleted](fg:red))";
    };
    nix_shell.disabled = true;
    fill.symbol = " ";

    cmd_duration = {
      format = slot "teal" "${timerIc} $duration";
      min_time = 1000;
    };

    time = {
      disabled = false;
      format = slot "yellow" "${clockIc} $time";
      time_format = "%H:%M:%S";
    };

    hostname = {
      disabled = false;
      ssh_only = true;
      format = slot "overlay1" "$hostname";
    };

    character = {
      success_symbol = "[${promptR}](bold green)";
      error_symbol = "[${promptR}](bold red)";
      vicmd_symbol = "[${promptL}](bold green)";
    };
  };

  configFile = (pkgs.formats.toml { }).generate "starship-base.toml" starshipConfig;

  noct = osConfig.host.home.noctalia;
  # fallback if noctalia doesn't exist as a theme option
  fallbackPalette = ''
    [palettes.fallback]
    overlay1 = "white"
    overlay2 = "white"
    yellow = "bright-yellow"
    peach = "yellow"
    red = "bright-red"
    blue = "bright-blue"
    teal = "bright-cyan"
    lavender = "bright-purple"
    green = "bright-green"
  '';
  fallbackFile = pkgs.writeText "starship-fallback.toml" fallbackPalette;
in
{
  home.packages = [ pkgs.starship ];

  # starship.toml stays mutable: noctalia rewrites everything from its ">>> NOCTALIA STARSHIP PALETTE >>>" marker onward
  home.activation.starshipConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (if noct then ''
    dest="$HOME/.config/starship.toml"
    sentinel="$HOME/.config/.starship-nix-src"
    marker="# >>> NOCTALIA STARSHIP PALETTE >>>"
    mkdir -p "$(dirname "$dest")"
    if [ "$(cat "$sentinel" 2>/dev/null)" != "${configFile}" ]; then
      # keep noctalia's palette block if already written; else plant the marker
      noctalia_tail=$(sed -n "/^$marker/,\$p" "$dest" 2>/dev/null || true)
      if [ -n "$noctalia_tail" ]; then
        { printf 'palette = "noctalia"\n'; cat "${configFile}"; printf '\n'; printf '%s\n' "$noctalia_tail"; } > "$dest"
      else
        { printf 'palette = "noctalia"\n'; cat "${configFile}"; printf '\n%s\n' "$marker"; } > "$dest"
      fi
      chmod u+w "$dest"
      printf '%s' "${configFile}" > "$sentinel"
    fi
  '' else ''
    dest="$HOME/.config/starship.toml"
    sentinel="$HOME/.config/.starship-nix-src"
    mkdir -p "$(dirname "$dest")"
    if [ "$(cat "$sentinel" 2>/dev/null)" != "${configFile}${fallbackFile}" ]; then
      # no noctalia -> fully static ANSI palette (nothing rewrites this file afterward)
      { printf 'palette = "fallback"\n'; cat "${configFile}"; printf '\n'; cat "${fallbackFile}"; } > "$dest"
      chmod u+w "$dest"
      printf '%s' "${configFile}${fallbackFile}" > "$sentinel"
    fi
  '');

  # Generate nushell init script at activation time.
  home.activation.starshipNushellInit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.cache/starship"
    ${pkgs.starship}/bin/starship init nu > "$HOME/.cache/starship/init.nu"
  '';

  programs.zsh.initContent = ''
    [[ "$TERM" != "linux" ]] && eval "$(${pkgs.starship}/bin/starship init zsh)"
  '';

  programs.nushell.extraConfig = ''
    if ($env | get -o TERM | default "xterm") != "linux" {
      source ~/.cache/starship/init.nu
    }
  '';
}
