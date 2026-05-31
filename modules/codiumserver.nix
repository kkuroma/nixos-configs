{ inputs, config, ... }:
{
  imports = [ inputs.vscodium-server.nixosModules.default ];
  services.vscodium-server.enable = config.host.features.codiumserver;
}
