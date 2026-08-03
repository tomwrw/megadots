{ inputs, self, ... }:
{
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.sops = {
    nixos =
      { config, ... }:
      {
        imports = [ inputs.sops-nix.nixosModules.sops ];
        sops = {
          defaultSopsFile = "${self}/secrets/hosts/${config.networking.hostName}.yaml";
          age.keyFile = "/persist/var/lib/sops-nix/key.txt";
          age.generateKey = false;
        };
      };

    homeManager =
      { config, lib, ... }:
      {
        imports = [ inputs.sops-nix.homeManagerModules.sops ];
        sops = {
          defaultSopsFile = "${self}/secrets/users/${config.home.username}.yaml";
          age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
          age.generateKey = false;
        };

        systemd.user.services.sops-nix = {
          Unit = {
            DefaultDependencies = false;
            Before = [
              "basic.target"
              "shutdown.target"
            ];
            Conflicts = [ "shutdown.target" ];
          };
          # sops-nix hardcodes Install.WantedBy = [ "default.target" ] with no
          # option to override it (modules/home-manager/sops.nix:391-392,
          # the `cfg.gnupg.home == null` branch). Secrets must be on disk
          # before dependent user services (e.g. syncthing) start, so pull
          # this to basic.target. mkForce is the minimal correct override;
          # revisit if sops-nix ever exposes a startup-target option.
          Install.WantedBy = lib.mkForce [ "basic.target" ];
        };
      };
  };
}
