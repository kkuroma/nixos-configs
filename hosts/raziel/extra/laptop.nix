{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.fw-ectool ];

  services.udev.packages = [ pkgs.brightnessctl ];

  services.logind.settings.Login = {
    HandlePowerKey = "suspend-then-hibernate";
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend-then-hibernate";
  };
  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "30min";
    HibernateOnACPower = true;
  };

  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.polkit-1.fprintAuth = true;
  services.fwupd.enable = true;

  # One-way to 10.10.30.0/24: raziel may initiate; that subnet may not open new connections back.
  networking.firewall.extraCommands = ''
    iptables -I nixos-fw 1 -s 10.10.30.0/24 -m conntrack --ctstate NEW -j nixos-fw-refuse
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -s 10.10.30.0/24 -m conntrack --ctstate NEW -j nixos-fw-refuse 2>/dev/null || true
  '';

  # The Mullvad exit node grabs all non-local traffic; --exit-node-allow-lan-access only
  # excludes the directly-connected /24. Keep the whole internal LAN off the tunnel — route
  # 10.10.0.0/16 via the gateway, not the exit node.
  networking.localCommands = ''
    ip rule del to 10.10.0.0/16 lookup main priority 5200 2>/dev/null || true
    ip rule add to 10.10.0.0/16 lookup main priority 5200
  '';


  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", KERNEL=="ucsi-source-psy-USBC000:00[14]", ACTION=="change", RUN+="${pkgs.writeShellScript "charge-limit" ''
      RIGHT_ON=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/ucsi-source-psy-USBC000:001/online)
      LEFT_ON=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/ucsi-source-psy-USBC000:004/online)

      AS_USER="${pkgs.util-linux}/bin/runuser -u kuroma -- env XDG_RUNTIME_DIR=/run/user/1000 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"

      # Only invoke user-session commands if a session is actually up.
      if [ -S /run/user/1000/bus ]; then HAS_SESSION=1; else HAS_SESSION=0; fi
      run_user() { [ "$HAS_SESSION" = "1" ] && $AS_USER "$@" || true; }

      if [ "$LEFT_ON" = "1" ]; then
        ${pkgs.fw-ectool}/bin/ectool fwchargelimit 80
        run_user /run/current-system/sw/bin/noctalia msg caffeine-enable
        run_user ${pkgs.libnotify}/bin/notify-send -i battery-caution-charging "Charge limit" "80% — left port"
      elif [ "$RIGHT_ON" = "1" ]; then
        ${pkgs.fw-ectool}/bin/ectool fwchargelimit 100
        run_user /run/current-system/sw/bin/noctalia msg caffeine-enable
        run_user ${pkgs.libnotify}/bin/notify-send -i battery-full-charging "Charge limit" "100% — right port"
      else
        run_user /run/current-system/sw/bin/noctalia msg caffeine-disable
      fi
    ''}"
  '';
}
