{
  description = "Python dev shell";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  outputs = { self, nixpkgs }:
  let pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; }; in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; [
        (python3.withPackages (ps: with ps; [ ipython numpy pandas scipy matplotlib ]))
        uv
        ruff
        black
        pyright
        jupyter
      ];
      shellHook = ''
        export DEV_SHELL=python
        exec zsh
      '';
    };
  };
}
