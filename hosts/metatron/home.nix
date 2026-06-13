{ ... }:
{
  # stateVersion + identity come from home/default.nix (shared entry).
  programs.zsh.shellAliases = {
    matrix-add-user = "sudo register_new_matrix_user -k $(sudo cat /run/secrets/matrix/registration-secret) http://localhost:8448";
  };

  home.file.".config/zsh-prompt.zsh".source = ../../config/zsh-prompt.zsh;

  programs.zsh.initContent = ''
    export TERM=xterm-256color
    source ~/.config/zsh-prompt.zsh
  '';
}
