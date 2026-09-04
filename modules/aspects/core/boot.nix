{ inputs, ... }:
{
  flake-file.inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # EFI boot settings, with systemd-boot and lanzaboote as alternative
  # sub-aspects. The settings below are shared: lanzaboote replaces the
  # installer but keeps the systemd-boot option names.
  den.aspects.boot = {
    nixos.boot.loader = {
      efi.canTouchEfiVariables = true;

      # The ESP is 1G and every generation is a whole UKI, so without a limit it
      # fills up and a rebuild dies half way through installing signed images. 8
      # rather than 10 because lanzaboote asserts a limit of 8 once measuredBoot
      # is on.
      systemd-boot.configurationLimit = 8;

      # Upstream defaults this on, which lets anyone at the console pass
      # init=/bin/sh and walk past Secure Boot. The cost is no cmdline editing,
      # so recovery means an installer USB.
      systemd-boot.editor = false;
    };

    provides.systemd-boot.nixos.boot.loader.systemd-boot.enable = true;

    provides.lanzaboote = {
      nixos =
        { pkgs, ... }:
        {
          imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

          boot.lanzaboote = {
            enable = true;
            pkiBundle = "/var/lib/sbctl";
            autoGenerateKeys.enable = true;
            autoEnrollKeys = {
              enable = true;
              autoReboot = true;
            };
            # allowUnsigned is left at its default, which is
            # autoGenerateKeys.enable - and that is what makes a from-scratch
            # deploy possible: lzbt runs inside nixos-install, but
            # generate-sb-keys.service only fires on the first real boot, so
            # pinning it false makes every deploy die on "Failed to read public
            # key from /var/lib/sbctl/keys/db/db.pem". The first install writes
            # unsigned UKIs; first boot generates the keys, enrolls them and
            # re-signs the ESP.
            #
            # Not the blanket "unsigned forever" it looks like: lzbt takes the
            # unsigned path only when *both* db.pem and db.key are missing.
          };

          # Secure Boot recovery ("sbctl verify", key re-enroll). Only the host
          # Secure Boot can lock me out of needs it.
          environment.systemPackages = [ pkgs.sbctl ];
        };

      persist.system.directories = [ "/var/lib/sbctl" ];
    };
  };
}
