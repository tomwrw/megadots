{ den, megadots, ... }:
{
  den.aspects.roles.base.includes = [
    megadots.core.nix
    megadots.core.locale
    megadots.core.security.openssh
    megadots.core.networking
    megadots.core.boot
    megadots.core.initrd
    megadots.core.security
    megadots.core.security.hardening
    megadots.core.security.fido2
    megadots.core.system-packages
    megadots.core.impermanence
    megadots.core.seed
    megadots.core.ephemeral-btrfs
    megadots.core.security.sops
    megadots.core.disko
    megadots.hardware
  ];
}
