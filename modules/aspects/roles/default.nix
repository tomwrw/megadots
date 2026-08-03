{ den, ... }:
{
  den.aspects.roles.default.includes = [
    den.aspects.core.nix
    den.aspects.core.unfree
    den.aspects.core.locale
    den.aspects.core.security.openssh
    den.aspects.core.networking
    den.aspects.core.boot
    den.aspects.core.initrd
    den.aspects.core.security
    den.aspects.core.security.hardening
    den.aspects.core.security.fido2
    den.aspects.core.system-packages
    den.aspects.core.impermanence
    den.aspects.core.security.sops
    den.aspects.core.disko
    den.aspects.hardware
    den.aspects.desktop.fonts
  ];
}
