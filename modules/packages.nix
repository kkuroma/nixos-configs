{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    neovim
    btop
    claude-code
    fastfetch
    zsh
    nushell
  ];
}
