{ inputs, ... }:
{
  flake-file.inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.core.boot = {
    # Loader-neutral, shared by every bootloader variant.
    nixos.boot.loader.efi.canTouchEfiVariables = true;

    provides.systemd-boot.nixos.boot.loader.systemd-boot.enable = true;

    provides.lanzaboote = {
      nixos = _: {
        imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

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

      persist.directories = [ "/var/lib/sbctl" ];
    };
  };
}
