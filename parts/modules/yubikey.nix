{ config, lib, pkgs, ... }:
lib.mkIf config.host.features.yubikey {
  services.pcscd.enable = true; # CCID for ykman oath/piv/openpgp
  services.udev.packages = [ pkgs.yubikey-personalization ];
  environment.systemPackages = [ pkgs.yubikey-manager ]; # ykman
  
  sops.secrets.u2f_keys.mode = "0444";
  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    settings = {
      cue = true;
      authfile = config.sops.secrets.u2f_keys.path;
    };
  };
  # MAXIMUM SECURITY MODE - required yubikey, password, and fprint (if available) to unlock
  security.pam.services = lib.genAttrs [ "sudo" "polkit-1" "swaylock" ] (svc: {
    u2fAuth = true;
    rules.auth.u2f.control = lib.mkForce "required";
    rules.auth.fprintd.control =
      lib.mkIf config.security.pam.services.${svc}.fprintAuth (lib.mkForce "required");
  }) // {
    login.u2fAuth = true;
  };
}
