{ inputs, ... }:
{

  flake.modules.nixos.secure-boot = {

    boot.loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
      limine = {
        enable = true;
        maxGenerations = 10;
        secureBoot = {
          enable = true;
          autoGenerateKeys = true;
          autoEnrollKeys.enable = true;
        };
      };
    };

    environment.persistence."/persist" = {
      directories = [ "/var/lib/sbctl" ];
    };
  };
}
