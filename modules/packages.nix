{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    neovim
    btop
    vivaldi
    ghostty
    claude-code
    fastfetch
    zsh
    nushell
  ];
}
