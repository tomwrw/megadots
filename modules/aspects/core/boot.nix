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
            # Left at its default, which is autoGenerateKeys.enable, i.e.
            # true. This is what makes a from-scratch deploy possible at all:
            # lzbt runs as the bootloader install hook inside nixos-install,
            # but generate-sb-keys.service is wantedBy multi-user.target and
            # so only fires on the first real boot. Pinning this false made
            # every 'just deploy' die on 'Failed to read public key from
            # /var/lib/sbctl/keys/db/db.pem'. The first install writes
            # unsigned UKIs, then first boot generates the keys, enrolls them
            # and re-signs the ESP.
            #
            # It is not the blanket "unsigned kernels forever" it looks like.
            # lzbt only takes the unsigned path when *both* db.pem and db.key
            # are missing, so a half-lost keypair still fails loudly, and a
            # fully-lost one gets regenerated and re-enrolled on that same
            # boot. checks.nix asserts it stays true.
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
