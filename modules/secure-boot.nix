{ config, ... }:
let
  limineModule = config.flake.modules.nixos.limine;
in
{
  flake.modules.nixos.secure-boot =
    { config, pkgs, ... }:
    {
      imports = [ limineModule ];

      boot.loader.limine.secureBoot = {
        enable = true;
        autoGenerateKeys = true;
        autoEnrollKeys.enable = true;
      };

      environment.persistence."/persist" = {
        directories = [ "/var/lib/sbctl" ];
      };

      # The limine installer runs before activation scripts and its auto-generate
      # path only fires when /var/lib/sbctl is absent — but impermanence already
      # bind-mounted the (empty) directory by then, so no keys are created and
      # the installer leaves an unsigned BOOTX64.EFI on the ESP. This is a temp
      # workaround. I raised an issue with limine to have this fixed. Waiting
      # on it being merged then I can rip this out.
      # https://github.com/NixOS/nixpkgs/issues/514756
      system.activationScripts.sbctl-bootstrap = {
        text = ''
          if [ ! -f /var/lib/sbctl/keys/PK/PK.pem ]; then
            ${pkgs.sbctl}/bin/sbctl create-keys
            ${pkgs.sbctl}/bin/sbctl enroll-keys --microsoft
            ${config.system.build.installBootLoader} $systemConfig
          fi
        '';
        deps = [ "specialfs" ];
      };
    };
}
