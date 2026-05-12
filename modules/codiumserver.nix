{ inputs, ... }:
{
  imports = [ inputs.vscodium-server.nixosModules.default ];
  services.vscodium-server.enable = true;
}