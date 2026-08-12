{ inputs, ... }:
let
  # Home-relative, because that is what both quirks below deal in. The
  # homeManager block turns it back into an absolute path against
  # config.home.homeDirectory rather than assuming /home/<user>.
  ageKeyFile = ".config/sops/age/keys.txt";
in
{
  flake-file.inputs.sops-nix = {
    url = "github:Mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  megadots.core.security.sops = {
    description = "sops-nix at both system and user scope, and the age key a deploy has to seed.";

    # The only thing that can decrypt my secrets, seeded by 'just deploy'. It
    # used to survive on its own while /home was a real subvolume. Named once
    # here and consumed twice: core.impermanence persists it, core.seed owns it
    # and tells the deploy recipe to bring it.
    #
    # This aspect is included at host scope (roles.base) and user scope (the
    # tomwrw aspect), so both keys below are produced twice. Only the user-scope
    # copies are read - core.impermanence's consumer runs per user, and 'seed'
    # is only resolvable where a user exists - which is exactly why home-persist
    # is a separate quirk from persist. Sharing one name would push a
    # home-relative path into environment.persistence as though it were absolute.
    home-persist.files = [ ageKeyFile ];

    # Through provides.to-users, unlike apps/security/ssh.nix which emits
    # 'seed' bare. This aspect is in roles.base as well as the user aspect, and
    # den decides how to resolve a quirk thunk by looking at its argument names
    # against the scope's context: at host scope there is no 'user', so a bare
    # { user, ... } here is classified as config-dependent and handed to the
    # module system, which fails with "attribute 'user' missing". Delivering
    # through to-users means it is only ever resolved in a user scope, where
    # that argument exists.
    provides.to-users.seed =
      { user, ... }:
      {
        owner = user.userName;
        files = [ ageKeyFile ];
      };

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
