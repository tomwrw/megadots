_: {
  megadots.virtualisation.libvirt.description = "libvirtd with virt-manager and a swtpm, for running VMs.";

  megadots.virtualisation.libvirt.nixos = _: {
    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };

    # No spice-vdagentd or spice-autorandr. Those are SPICE guest agents, they
    # belong inside a VM so the client can drive its clipboard and resolution.
    # On the host they just sit in graphical.target doing nothing. The client
    # side is virt-manager, below.
    #
    # No package set, pkgs.virt-manager is already the module default.
    programs.virt-manager.enable = true;

    # virt-secret-init-encryption.service writes the secrets key into this
    # directory without creating it, so on the first boot of a fresh
    # impermanent root it can lose the race against whatever else makes it.
    # 0700 because it holds an encrypted credential and the caller's UMask
    # doesn't reach a directory it didn't create.
    systemd.tmpfiles.rules = [ "d /var/lib/libvirt/secrets 0700 root root -" ];

    # libvirt's own drop-in pulls the secrets key in with
    # LoadCredentialEncrypted, which needs the host credential key at
    # /var/lib/systemd/credential.secret to decrypt it. Both sides are
    # persisted, but a 'just deploy' reinstall has produced a key encrypted
    # against a host secret that never reached /persist, and then
    # virt-secret-init-encryption.service can't repair it: its
    # ConditionPathExists=!<the key> means an unusable key is as good as a
    # working one, so it stays skipped and libvirtd fails 243/CREDENTIALS on
    # every boot from then on.
    #
    # So test the key before that condition is evaluated and throw it away if
    # this host can no longer read it. The removal is safe as long as nothing
    # defines libvirt secrets (virsh secret-define), which is what this key
    # actually encrypts - VM disks and swtpm state are unaffected.
    systemd.services.virt-secret-drop-stale-key = {
      description = "Discard a libvirt secrets key this host cannot decrypt";
      before = [ "virt-secret-init-encryption.service" ];
      wantedBy = [ "libvirtd.service" ];
      unitConfig = {
        ConditionPathExists = "/var/lib/libvirt/secrets/secrets-encryption-key";
        RequiresMountsFor = "/var/lib/libvirt /var/lib/systemd";
      };
      serviceConfig.Type = "oneshot";
      # Plaintext to /dev/null, but stderr stays in the journal so the reason
      # for a removal is on record. Never fails: a stale key is a thing to fix
      # silently, not a reason to hold libvirtd down.
      script = ''
        if ! systemd-creds decrypt --name=secrets-encryption-key \
             /var/lib/libvirt/secrets/secrets-encryption-key - >/dev/null; then
          echo "secrets-encryption-key is undecryptable on this host, removing it so it gets regenerated"
          rm -f /var/lib/libvirt/secrets/secrets-encryption-key
        fi
      '';
    };
  };

  megadots.virtualisation.libvirt.persist.directories = [
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
  megadots.virtualisation.libvirt.provides.to-users =
    { host, user, ... }:
    {
      name = "virtualisation.libvirt/libvirtd-group(${user.userName}@${host.name})";
      nixos.users.users.${user.userName}.extraGroups = [ "libvirtd" ];
    };
}
