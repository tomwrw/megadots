{
  flake.modules.nixos.secure-boot =
    { config, pkgs, ... }:
    {
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

      # The limine installer runs before activation scripts and its auto-generate
      # path only fires when /var/lib/sbctl is absent — but impermanence already
      # bind-mounted the (empty) directory by then, so no keys are created and
      # the installer leaves an unsigned BOOTX64.EFI on the ESP. Bootstrap keys
      # here when missing, then re-invoke installBootLoader so it signs against
      # the keys that now exist. --firmware-builtin is omitted because OVMF in
      # Setup Mode has no dbDefault variable to import from; revisit if/when
      # this module gets used on hardware that ships vendor-builtin keys.
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
