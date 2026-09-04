{ inputs, ... }:
let
  # Home-relative, because that is what persist.home deals in. The homeManager
  # block turns it back into an absolute path against home.homeDirectory rather
  # than assuming /home/<user>.
  ageKeyDir = ".config/sops/age";
  ageKeyFile = "${ageKeyDir}/keys.txt";
in
{
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # sops-nix at both system and user scope, with the age key directory kept
  # across the rollback.
  den.aspects.sops = {
    # The directory rather than the keys.txt inside it, matching apps/ssh.nix: a
    # deploy drops the key here before the machine has ever booted, so the
    # container covers the file however it arrives. It also sidesteps
    # impermanence file handling, which breaks on writers that rename over their
    # target - see apps/zsh.nix.
    #
    # Included at both host and user scope, so this is emitted twice and only
    # the user-scope copy is read. That is why persist.home is a separate key
    # from persist.system: one flat list would push a home-relative path into
    # environment.persistence as though it were absolute.
    persist.home.directories = [ ageKeyDir ];

    nixos =
      { config, ... }:
      {
        imports = [ inputs.sops-nix.nixosModules.sops ];
        sops = {
          defaultSopsFile = ../../../secrets/hosts/${config.networking.hostName}.yaml;
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
          defaultSopsFile = ../../../secrets/users/${config.home.username}.yaml;
          age.keyFile = "${config.home.homeDirectory}/${ageKeyFile}";
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
