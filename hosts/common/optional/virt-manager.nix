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

  networking.firewall.trustedInterfaces = [ "br0" ];

  programs.virt-manager = {
    enable = true;
    package = pkgs.virt-manager;
  };
  # This app/config requires the following persisted directories
  # and folders. Be This will only apply if impermanence is
  # enabled, and as soon as a user and host become out of
  # scope for this module, the items here will no longer
  # be persisted (they'll still exist in /persist thought).
  environment.persistence."/persist" = {
    directories = [
      "/var/cache/libvirt"
      "/var/lib/libvirt"
      "/var/lib/qemu"
    ];
  };
}
