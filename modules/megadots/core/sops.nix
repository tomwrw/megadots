{ inputs, ... }:
let
  # Home-relative, because that is what the home-persist quirk deals in. The
  # homeManager block turns it back into an absolute path against
  # config.home.homeDirectory rather than assuming /home/<user>.
  ageKeyDir = ".config/sops/age";
  ageKeyFile = "${ageKeyDir}/keys.txt";
in
{
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  megadots.core.sops = {
    description = "sops-nix at both system and user scope, with the user's age key directory persisted.";

    # The directory holding the only thing that can decrypt my user secrets. It
    # used to survive on its own while /home was a real subvolume.
    #
    # The directory rather than the keys.txt file inside it, matching
    # apps/security/ssh.nix: a deploy drops the key here before the machine has
    # ever booted, and persisting the container means the file is covered
    # however it arrives. It also sidesteps impermanence's file handling, which
    # leaves a symlink until the /persist copy exists and breaks on writers
    # that rename over their target - the failure apps/shell/zsh.nix documents
    # for shell history.
    #
    # This aspect is included at host scope (roles.base) and user scope (the
    # tomwrw aspect), so this is produced twice and only the user-scope copy is
    # read: core.impermanence's consumer runs per user. That is exactly why
    # home-persist is a separate quirk from persist - sharing one name would
    # push a home-relative path into environment.persistence as though it were
    # absolute.
    home-persist.directories = [ ageKeyDir ];

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
