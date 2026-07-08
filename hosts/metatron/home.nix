{ ... }:
{
  # stateVersion + identity come from home/default.nix (shared entry).
  programs.zsh.shellAliases = {
    matrix-add-user = "sudo register_new_matrix_user -k $(sudo cat /run/secrets/matrix/registration-secret) http://localhost:8448";
  };
  # Prompt comes from home/base/starship.nix (noctalia-off → static fallback palette).
}
