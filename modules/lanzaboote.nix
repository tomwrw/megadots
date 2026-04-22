{inputs, ...}: {
  flake-file.inputs = {
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  flake.modules.nixos.lanzaboote = {
    imports = [inputs.lanzaboote.nixosModules.lanzaboote];

    boot.loader.systemd-boot.enable = false;
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

    environment.persistence."/persist" = {
      directories = ["/var/lib/sbctl"];
    };
  };
}
