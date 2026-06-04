{
  lib,
  den,
  ...
}:
{
  den.aspects.tomwrw =
    { host, ... }:
    {

      includes = [
        den.provides.primary-user
        (den.provides.user-shell "fish")
        den.provides.define-user
        den.aspects.sops
      ];

      nixos =
        {
          pkgs,
          config,
          ...
        }:
        {
          users.mutableUsers = false;

          # tomwrw's login password is provisioned per-host from that host's sops
          # file (key users/tomwrw/password). `neededForUsers` decrypts it early
          # enough for user creation (to /run/secrets-for-users). Every host's
          # secrets/hosts/<host>.yaml must define this key, and the value must be
          # a *hashed* password (e.g. `mkpasswd -m sha-512`), not plaintext.
          sops.secrets."users/tomwrw/password".neededForUsers = true;

          users.users.tomwrw = {
            hashedPasswordFile = config.sops.secrets."users/tomwrw/password".path;
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFCIJ1LhkFDBZaZU/bf8Y3XyCXb3RnVxg4gRs6i+XbSe tomwrw@proton.me"
            ];
            extraGroups = [
              "disk"
              "i2c"
              "networkmanager"
              "wheel"
            ];
          };

          # Files shipped via `nixos-anywhere --extra-files` land root-owned, and
          # --extra-files also creates their parent dirs (.config, .config/sops)
          # as root before the user exists — NixOS only chowns the home dir
          # itself, not nested subdirs. Hand every seeded dir + file to tomwrw so
          # HM activation (and ssh) can use them. Covers the SSH keypair too (not
          # a sops concern, but shipped the same way).
          systemd.tmpfiles.rules = [
            "d /home/tomwrw/.ssh 0700 tomwrw users -"
            "z /home/tomwrw/.ssh/id_ed25519 0600 tomwrw users -"
            "z /home/tomwrw/.ssh/id_ed25519.pub 0644 tomwrw users -"
            "d /home/tomwrw/.config 0755 tomwrw users -"
            "d /home/tomwrw/.config/sops 0700 tomwrw users -"
            "d /home/tomwrw/.config/sops/age 0700 tomwrw users -"
            "z /home/tomwrw/.config/sops/age/keys.txt 0600 tomwrw users -"
          ];
        };

      homeManager =
        { pkgs, ... }:
        {
          home.username = "tomwrw";
          home.homeDirectory = "/home/tomwrw";
          home.stateVersion = "26.05";

          programs.git.settings.user.name = "tomwrw";
          programs.git.settings.user.email = "tomwrw@proton.me";
        };

      provides.endgame = {
        includes = [
          den.aspects.gaming
        ];
      };
    };
}
