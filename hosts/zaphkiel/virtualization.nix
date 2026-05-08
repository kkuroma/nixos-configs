{ pkgs, ... }:
{
  # docker - nvidia enabled because this is an nvidia machine
  virtualisation.docker = {
    enable = true;
  };

  # podman - for distrobox
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;
  };

  # KVM/qemu with libvertd - VMs
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
    };
  };
  programs.virt-manager.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;  # enable copy and paste between host and guest
}
