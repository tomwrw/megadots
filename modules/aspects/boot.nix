{ ... }:
{
  # Default bootloader baseline for every NixOS host: systemd-boot on UEFI.
  # Pulled in via den.aspects.base. Hosts that want Secure Boot additionally
  # include den.aspects.secure-boot, which overrides this — it force-disables
  # systemd-boot and hands over to lanzaboote.
  den.aspects.boot.nixos = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
