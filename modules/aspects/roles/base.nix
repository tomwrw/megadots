{ den, ... }:
{
  # The baseline every machine takes, headless or not.
  den.aspects.base.includes = [
    # Boot, disks and the rollback
    den.aspects.boot
    den.aspects.disko
    den.aspects.ephemeral-btrfs
    den.aspects.impermanence
    den.aspects.initrd

    # Networking
    den.aspects.networking
    den.aspects.openssh

    # Security and secrets
    den.aspects.fido2
    den.aspects.hardening
    den.aspects.security
    den.aspects.sops

    # The rest of the baseline
    den.aspects.firmware
    den.aspects.locale
    den.aspects.nix
    den.aspects.system-packages
  ];
}
