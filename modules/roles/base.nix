{ den, megadots, ... }:
{
  den.aspects.roles.base.includes = [
    megadots.core.nix
    megadots.core.locale
    megadots.core.openssh
    megadots.core.networking
    megadots.core.boot
    megadots.core.initrd
    megadots.core.security
    megadots.core.hardening
    megadots.core.fido2
    megadots.core.system-packages
    megadots.core.impermanence
    megadots.core.ephemeral-btrfs
    megadots.core.sops
    megadots.core.disko
    megadots.core.firmware
  ];
}
