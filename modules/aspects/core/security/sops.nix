{ inputs, ... }:
{
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.core.security.sops = {
    nixos =
      { config, ... }:
      {
        imports = [ inputs.sops-nix.nixosModules.sops ];
        sops = {
          defaultSopsFile = ../../../../secrets/hosts/${config.networking.hostName}.yaml;
          age.keyFile = "/persist/var/lib/sops-nix/key.txt";
          age.generateKey = false;
          # Exactly one decryption identity, stated explicitly. sops-nix
          # otherwise defaults sshKeyPaths to the ed25519 key from
          # services.openssh.hostKeys and converts it to an age identity at
          # activation - a second, implicit path that would quietly change
          # decryption behaviour if the host key were ever rotated.
          age.sshKeyPaths = [ ];
        };
      };

    homeManager =
      { config, lib, ... }:
      {
        imports = [ inputs.sops-nix.homeManagerModules.sops ];
        sops = {
          defaultSopsFile = ../../../../secrets/users/${config.home.username}.yaml;
          age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
          age.generateKey = false;
        };

        # The only identity that can decrypt this user's secrets, seeded by
        # `just deploy` via nixos-anywhere --extra-files. It survived on its own
        # while /home was a persistent subvolume; now it needs stating. Kept
        # beside age.keyFile above rather than with the ssh keys, so the path
        # and the thing that persists it cannot drift.
        home.persistence."/persist".files = [ ".config/sops/age/keys.txt" ];

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
          # the 'cfg.gnupg.home == null' branch). Secrets must be on disk
          # before dependent user services (e.g. syncthing) start, so pull
          # this to basic.target. mkForce is the minimal correct override;
          # revisit if sops-nix ever exposes a startup-target option.
          Install.WantedBy = lib.mkForce [ "basic.target" ];
        };
      };
  };
}
