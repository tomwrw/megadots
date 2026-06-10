{ den, ... }:
{
  den.aspects.base.includes = [
    den.aspects.nix
    den.aspects.unfree
    den.aspects.locale
    den.aspects.ssh
    den.aspects.networking
    den.aspects.hardware
    den.aspects.kernel
    den.aspects.disko
    den.aspects.boot
    den.aspects.systemd-initrd
    den.aspects.sops
    den.aspects.system-packages
    den.aspects.fonts
    den.aspects.security
    den.aspects.hardening
  ];
}
