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
        den.aspects.syncthing
        den.aspects.firefox
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

          # `--extra-files` seeds these dirs + files root-owned (before the user
          # exists). tmpfiles `d` owns the dirs fine, but systemd-tmpfiles refuses
          # to chown a *file* once the path runs through tomwrw-owned dirs (its
          # safe-path protection), so the key files stay root-owned. The oneshot
          # below owns them from root instead, before HM activation reads them.
          systemd.tmpfiles.rules = [
            "d /home/tomwrw/.ssh 0700 tomwrw users -"
            "d /home/tomwrw/.config 0755 tomwrw users -"
            "d /home/tomwrw/.config/sops 0700 tomwrw users -"
            "d /home/tomwrw/.config/sops/age 0700 tomwrw users -"
          ];

          systemd.services.tomwrw-seeded-keys = {
            description = "Own tomwrw's deploy-seeded key files";
            wantedBy = [ "multi-user.target" ];
            before = [ "home-manager-tomwrw.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              chown tomwrw:users \
                /home/tomwrw/.config/sops/age/keys.txt \
                /home/tomwrw/.ssh/id_ed25519 \
                /home/tomwrw/.ssh/id_ed25519.pub || true
            '';
          };
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
