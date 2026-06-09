# Secret management via sops-nix, for both NixOS hosts and the Home Manager user.
#
# Dedicated, pre-generated age keys (one per host, one per user) are shipped to
# the target during install via `nixos-anywhere --extra-files` (see justfile).
# Only public keys (.sops.yaml) and encrypted secrets (secrets/**) are committed;
# private keys live on a LUKS USB stick and never enter the repo.
#
# One aspect, two classes: hosts include it (via den.aspects.base) and pick up the
# `nixos` class; the user includes it and picks up `homeManager`. Each class
# derives its own per-entity secrets file, so the aspect stays reusable.
#
# Secret paths are anchored at the flake root via `self` (its outPath is the
# project root) rather than depth-relative `../../`, so this file can move.
{ inputs, self, ... }:
{
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.sops = {
    # Host secrets — decrypted with the host's dedicated age key on /persist.
    nixos =
      { config, ... }:
      {
        imports = [ inputs.sops-nix.nixosModules.sops ];
        sops = {
          defaultSopsFile = "${self}/secrets/hosts/${config.networking.hostName}.yaml";
          age.keyFile = "/persist/var/lib/sops-nix/key.txt";
          age.generateKey = false;
          # Individual host secrets are declared where they're consumed
          # (e.g. the tomwrw password in modules/users/tomwrw/tomwrw.nix).
        };
      };

    # User secrets — decrypted with the user's dedicated age key in their home.
    homeManager =
      { config, lib, ... }:
      {
        imports = [ inputs.sops-nix.homeManagerModules.sops ];
        sops = {
          defaultSopsFile = "${self}/secrets/users/${config.home.username}.yaml";
          age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
          age.generateKey = false;
          # Individual user secrets are declared by the user module as needed.
        };

        # Decrypt secrets early in the user session — before basic.target, so any
        # secret-consuming user service (e.g. Syncthing reading its provisioned
        # cert/key) finds them on a cold boot instead of racing the decryption.
        # This is generic and keeps consumers decoupled from sops. It's a *want*
        # of basic.target, so a decrypt failure logs but doesn't wedge the session.
        systemd.user.services.sops-nix = {
          Unit = {
            DefaultDependencies = false;
            Before = [
              "basic.target"
              "shutdown.target"
            ];
            Conflicts = [ "shutdown.target" ];
          };
          Install.WantedBy = lib.mkForce [ "basic.target" ];
        };
      };
  };
}
