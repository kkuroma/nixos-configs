{ pkgs, ... }:
# Headless dev toolchain — installed with the dev tier (host.home.dev), any profile.
# Heavy/GUI dev bits (texliveFull, vscodium) stay in the desktop layer.
{
  home.packages = with pkgs; [
    (python3.withPackages (ps: with ps; [ tqdm numpy pandas scipy matplotlib requests ipython ]))
    uv
    nodejs
    claude-code
    distrobox
    # nvim formatters (conform-nvim)
    nixfmt
    black
    stylua
    prettier
  ];
}
