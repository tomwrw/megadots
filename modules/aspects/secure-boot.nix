{ inputs, ... }:
{
  flake-file.inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.secure-boot.nixos =
    { lib, ... }:
    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

      # Replace the default bootloader from den.aspects.boot: force systemd-boot
      # off and hand over to lanzaboote. (canTouchEfiVariables is already set by
      # the boot aspect; lanzaboote's lzbt installer doesn't consult it anyway.)
      boot.loader.systemd-boot.enable = lib.mkForce false;

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
  # emit it on the 'persist' quirk (declared by the preservation aspect).
  # Preservation consumes it IF this host runs it; on hosts without
  # preservation there is simply no consumer, so this is a harmless no-op with
  # no coupling to the preservation option.
  den.aspects.secure-boot.persist.directories = [ "/var/lib/sbctl" ];
}
