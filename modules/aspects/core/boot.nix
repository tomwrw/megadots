{ inputs, ... }:
{
  flake-file.inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.core.boot = {
    # Shared by both bootloaders. lanzaboote replaces the installer but keeps
    # the systemd-boot option names, so setting these here covers both.
    nixos.boot.loader = {
      efi.canTouchEfiVariables = true;

      # My ESP is 1G and every generation is a whole UKI, so without a limit it
      # fills up and a rebuild dies half way through installing signed images.
      # 8 and not 10 because lanzaboote asserts a limit of 8 once measuredBoot
      # is on, and I want that option open.
      systemd-boot.configurationLimit = 8;

      # Upstream defaults this on, which lets anyone at the console pass
      # init=/bin/sh from the boot menu and walk straight past Secure Boot. The
      # cost is no cmdline editing, so recovery means an installer USB.
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
            # Pin this, because autoGenerateKeys stays on. allowUnsigned
            # defaults to autoGenerateKeys.enable, so left implicit every
            # activation runs 'lzbt install --allow-unsigned true'. If the
            # signing key ever goes missing I want a loud failure, not
            # unsigned kernels.
            allowUnsigned = false;
          };

          # Secure Boot recovery tool ('sbctl verify', key re-enroll). Only the
          # host that Secure Boot can lock me out of needs it, so it goes here
          # and not in my base packages.
          environment.systemPackages = [ pkgs.sbctl ];
        };

      persist.directories = [ "/var/lib/sbctl" ];
    };
  };
}
