# Claude Code plus the Kuroma manual, wired through native paths rather than the plugin marketplace
{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  style = inputs.coding-style;

  # Every skill directory in the manual, linked one by one so registry.json stays out of the scan
  skills = [
    "kuroma-writing"
    "kuroma-layout"
    "kuroma-workloop"
    "kuroma-compare"
  ];

  # The marketplace would own settings.json, which the TUI rewrites, so only hooks are merged in
  hooks = {
    SessionStart = [
      {
        hooks = [
          {
            type = "command";
            command = "${pkgs.python3}/bin/python3 ${style}/hooks/brevity.py";
            timeout = 5;
            statusMessage = "Loading style rules";
          }
        ];
      }
    ];
    PostToolUse = [
      {
        matcher = "Edit|Write";
        hooks = [
          {
            type = "command";
            command = "${pkgs.python3}/bin/python3 ${style}/hooks/comment_lint.py";
            timeout = 10;
            statusMessage = "Checking comment style";
          }
        ];
      }
    ];
  };

  fragment = pkgs.writeText "claude-hooks.json" (builtins.toJSON { inherit hooks; });
in
{
  home.packages = [ pkgs.claude-code ];

  home.file = builtins.listToAttrs (
    map (name: {
      name = ".claude/skills/${name}";
      value.source = "${style}/skills/${name}";
    }) skills
  );

  # Merge rather than overwrite, so /config, /model and the theme picker keep working
  home.activation.claudeStyleHooks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.claude/settings.json"
    run mkdir -p "$HOME/.claude"
    [ -f "$settings" ] || echo '{}' > "$settings"
    run ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$settings" ${fragment} > "$settings.tmp"
    run mv "$settings.tmp" "$settings"
  '';
}
