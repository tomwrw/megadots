{ ... }:
{
  den.aspects.secure-boot.nixos =
    { lib, ... }:
    {
      boot.loader.systemd-boot.enable = lib.mkForce false;

      # Conventional EFI baseline (matches lanzaboote's own test config).
      # NB: lanzaboote installs via boot.loader.external/lzbt and does not read
      # this option, so it is currently inert — boot-entry registration and key
      # enrollment happen at runtime and depend on the firmware (UEFI + Secure
      # Boot in setup mode + writable efivars), not on this flag. Kept as the
      # correct baseline and in case the bootloader ever changes.
      boot.loader.efi.canTouchEfiVariables = true;

      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
        autoGenerateKeys.enable = true;
        autoEnrollKeys = {
          enable = true;
          autoReboot = true;
        };
      };
    };

  # The Secure Boot key material in /var/lib/sbctl must survive reboots, so
  # emit it on the `persist` quirk (declared by the preservation aspect).
  # Preservation consumes it IF this host runs it; on hosts without
  # preservation there is simply no consumer, so this is a harmless no-op with
  # no coupling to the preservation option.
  den.aspects.secure-boot.persist.directories = [ "/var/lib/sbctl" ];
}
