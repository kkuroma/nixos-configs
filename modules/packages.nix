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
    foot
    claude-code
    fastfetch
    zsh
    nushell
  ];
}
