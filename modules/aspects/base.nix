{ den, ... }:
{
  # Meta-aspect: the common baseline every NixOS host gets. Hosts include
  # this aspect for the full bundle; if a host wants to opt out of a piece
  # (e.g. a headless server skipping NetworkManager), it can include the
  # individual aspects directly instead.
  den.aspects.base.includes = [
    den.aspects.nix
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
