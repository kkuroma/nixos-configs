{ pkgs, config, lib, ... }:
let
  # Disable libvirt's DNS listener so it doesn't conflict with AdGuard on port 53.
  # dnsmasq:options hands out 192.168.122.1 (the bridge IP) as DNS via DHCP option 6;
  # AdGuard on 0.0.0.0:53 answers there, so VMs get full AdGuard DNS.
  libvirtDefaultNetwork = pkgs.writeText "libvirt-default-network.xml" ''
    <network xmlns:dnsmasq='http://libvirt.org/schemas/network/dnsmasq/1.0'>
      <name>default</name>
      <!-- Pin the uuid so net-define matches our own network by uuid and updates it in
           place on later switches (no destroy → no blip), instead of colliding. -->
      <uuid>c4e8a1f2-3b6d-4a09-8e57-1d2c3b4a5f60</uuid>
      <forward mode="nat"/>
      <bridge name="virbr0" stp="on" delay="0"/>
      <dns enable="no"/>
      <ip address="192.168.122.1" netmask="255.255.255.0">
        <dhcp>
          <range start="192.168.122.2" end="192.168.122.254"/>
        </dhcp>
      </ip>
      <dnsmasq:options>
        <dnsmasq:option value="dhcp-option=6,192.168.122.1"/>
      </dnsmasq:options>
    </network>
  '';
in
lib.mkIf config.host.features.virtualization {
  virtualisation.docker = {
    enable = true;
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
    };
  };
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # virsh net-define updates libvirt's internal network state (unlike writing the XML
  # file directly, which libvirt ignores for already-defined networks).
  # preStart removes the autostart symlink so libvirtd doesn't race to start the old
  # network before this service can redefine it.
  systemd.services.libvirtd.preStart = lib.mkAfter ''
    rm -f /var/lib/libvirt/qemu/networks/autostart/default.xml
  '';

  systemd.services.libvirt-default-network = {
    description = "Configure libvirt default network (AdGuard-compatible, no DNS listener)";
    after = [ "libvirtd.service" ];
    requires = [ "libvirtd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      virsh="${lib.getExe' pkgs.libvirt "virsh"}"
      # net-define matches by uuid → once migrated to our pinned uuid it just updates in
      # place. A foreign 'default' (libvirt's stock one, different uuid) won't match and
      # net-define errors — so tear it down once and redefine. All tolerant = idempotent.
      if ! $virsh net-define ${libvirtDefaultNetwork} 2>/dev/null; then
        $virsh net-destroy default 2>/dev/null || true
        $virsh net-undefine default 2>/dev/null || true
        $virsh net-define ${libvirtDefaultNetwork}
      fi
      $virsh net-autostart default
      $virsh net-start default 2>/dev/null || true
    '';
  };
}
