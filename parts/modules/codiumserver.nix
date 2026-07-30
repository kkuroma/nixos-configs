{ inputs, config, ... }:
{
  imports = [ "${inputs.vscodium-server}/modules/vscodium-server" ];
  services.vscodium-server.enable = config.host.features.codiumserver;
}
