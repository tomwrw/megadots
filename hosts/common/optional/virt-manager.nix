{ pkgs, ... }:
{
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        # Enable software TPM for QEMU
        swtpm.enable = true;
      };
    };
  };

  services = {
    spice-autorandr.enable = true;
    spice-vdagentd.enable = true;
  };

  programs.virt-manager = {
    enable = true;
    package = pkgs.virt-manager;
  };

  preservation = {
    preserveAt."/persist" = {
      directories = [
        "/var/cache/libvirt"
        "/var/lib/libvirt"
        "/var/lib/qemu"
      ];
    };
  };
}
