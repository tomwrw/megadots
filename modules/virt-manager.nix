{
  flake.modules.nixos.gaming = {pkgs, ...}: {
    virtualisation = {
      libvirtd = {
        enable = true;
        qemu.swtpm.enable = true;
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

    environment.persistence."/persist" = {
      directories = [
        "/var/cache/libvirt"
        "/var/lib/libvirt"
        "/var/lib/qemu"
      ];
    };

    # Without this, virt-secret-init-encryption.service races libvirtd to write
    # the encryption key into a directory that doesn't exist yet and fails on
    # the first boot of a fresh impermanent root.
    systemd.tmpfiles.rules = [
      "d /var/lib/libvirt/secrets 0700 root root -"
    ];
  };
}
