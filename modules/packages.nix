{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    neovim
    btop
    vscodium
    vivaldi
    ghostty
    claude-code
    fastfetch
    zsh
    nushell
  ];
}
