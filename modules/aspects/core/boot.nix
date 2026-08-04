{ inputs, ... }:
{
  flake-file.inputs.lanzaboote = {
    url = "github:nix-community/lanzaboote";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.core.boot = {
    # Loader-neutral, shared by every bootloader variant. lanzaboote reads both
    # of the systemd-boot options below (it replaces the installer, not the
    # option namespace), so setting them here covers every host.
    nixos.boot.loader = {
      efi.canTouchEfiVariables = true;

      # The ESP is 1G (core/disko.nix) and every generation is a UKI: kernel +
      # initrd + cmdline in one signed file. Unbounded generations fill it, and
      # on the Secure Boot host the failure mode is 'nixos-rebuild switch' dying
      # part-way through installing signed images. 8 rather than 10 because
      # lanzaboote asserts configurationLimit <= 8 once measuredBoot is enabled,
      # so this keeps that door open.
      systemd-boot.configurationLimit = 8;

      # Upstream defaults this to true, which lets anyone at the console append
      # kernel parameters (init=/bin/sh) from the boot menu - undercutting the
      # point of measured/Secure Boot. Trade-off: no boot-menu cmdline editing,
      # so recovery means a NixOS installer USB.
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
            # Must be pinned BECAUSE autoGenerateKeys stays on permanently:
            # allowUnsigned defaults to autoGenerateKeys.enable, so leaving it
            # implicit means 'lzbt install' runs with --allow-unsigned true on
            # every activation. If the signing key in pkiBundle ever goes missing,
            # unsigned kernels would be installed silently instead of the build
            # failing loudly.
            allowUnsigned = false;
          };

          # sbctl is the Secure Boot recovery tool ('sbctl verify', key
          # re-enroll), so it belongs on the host that Secure Boot can lock out
          # rather than in the fleet-wide package set.
          environment.systemPackages = [ pkgs.sbctl ];
        };

      persist.directories = [ "/var/lib/sbctl" ];
    };
  };
}
