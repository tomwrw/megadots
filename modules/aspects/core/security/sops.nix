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
          # One decryption identity, spelled out. Otherwise sops-nix defaults
          # sshKeyPaths to the ed25519 host key and turns it into an age
          # identity at activation, which is a second way in that would change
          # behaviour if I ever rotated the host key.
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

        # The only thing that can decrypt my secrets, seeded by 'just deploy'.
        # It used to survive on its own while /home was a real subvolume. Kept
        # next to age.keyFile above and not with the ssh keys, so the path and
        # the thing persisting it can't drift apart.
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
          # sops-nix hardcodes WantedBy = default.target with no way to
          # override it, but my secrets have to be on disk before syncthing
          # starts, so pull it forward to basic.target. mkForce is the
          # smallest thing that works. Revisit if sops-nix ever gives me an
          # option for this.
          Install.WantedBy = lib.mkForce [ "basic.target" ];
        };
      };
  };
}
