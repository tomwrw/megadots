_: {
  # libvirtd with virt-manager and a swtpm, for running VMs.
  den.aspects.libvirt.nixos = _: {
    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };

    # No spice-vdagentd or spice-autorandr: those are guest agents and belong
    # inside a VM. The client side is virt-manager.
    programs.virt-manager.enable = true;

    # virt-secret-init-encryption.service writes the secrets key into this
    # directory without creating it, so on the first boot of a fresh
    # impermanent root it can lose the race against whatever else makes it.
    # 0700 because it holds an encrypted credential and the caller's UMask
    # doesn't reach a directory it didn't create.
    systemd.tmpfiles.rules = [ "d /var/lib/libvirt/secrets 0700 root root -" ];

    # libvirt loads its secrets key with LoadCredentialEncrypted, which needs
    # /var/lib/systemd/credential.secret to decrypt. A reinstall can leave a key
    # encrypted against a host secret that never reached /persist, and
    # virt-secret-init-encryption.service will not repair it - its
    # ConditionPathExists=!<key> treats an unusable key as a working one, so
    # libvirtd fails 243/CREDENTIALS on every boot from then on.
    #
    # So test the key before that condition is evaluated and discard it if this
    # host cannot read it. Safe unless something defines libvirt secrets (virsh
    # secret-define); VM disks and swtpm state are unaffected.
    systemd.services.virt-secret-drop-stale-key = {
      # Discard a libvirt secrets key this host cannot decrypt
      before = [ "virt-secret-init-encryption.service" ];
      wantedBy = [ "libvirtd.service" ];
      unitConfig = {
        ConditionPathExists = "/var/lib/libvirt/secrets/secrets-encryption-key";
        RequiresMountsFor = "/var/lib/libvirt /var/lib/systemd";
      };
      serviceConfig.Type = "oneshot";
      # Never fails: a stale key is a thing to fix silently, not a reason to
      # hold libvirtd down. stderr stays in the journal so a removal is on record.
      script = ''
        if ! systemd-creds decrypt --name=secrets-encryption-key \
             /var/lib/libvirt/secrets/secrets-encryption-key - >/dev/null; then
          echo "secrets-encryption-key is undecryptable on this host, removing it so it gets regenerated"
          rm -f /var/lib/libvirt/secrets/secrets-encryption-key
        fi
      '';
    };
  };

  den.aspects.libvirt.persist.system.directories = [
    "/var/cache/libvirt"
    "/var/lib/libvirt"
    # The local CA that issues vTPM endorsement certificates. Per-VM swtpm
    # state sits under /var/lib/libvirt but this CA doesn't, and without it
    # every vTPM gets a fresh EK certificate each boot.
    "/var/lib/swtpm-localca"
    # Not /var/lib/qemu. The libvirtd module refills it with tmpfiles symlinks
    # into the store every boot, so persisting it just collects dangling links
    # as the store gets collected.
  ];

  # The aspect that makes the libvirtd group is the one that grants it. Only
  # hosts including this aspect deliver it, so the user side needs no guard.
  den.aspects.libvirt.provides.to-users =
    { host, user, ... }:
    {
      name = "virtualisation.libvirt/libvirtd-group(${user.userName}@${host.name})";
      nixos.users.users.${user.userName}.extraGroups = [ "libvirtd" ];
    };
}
