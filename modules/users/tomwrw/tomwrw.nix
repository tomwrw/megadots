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
        den.batteries.primary-user
        (den.batteries.user-shell "zsh")
        den.batteries.define-user
        den.aspects.sops
        den.aspects.syncthing
        den.aspects.firefox
        den.aspects.git
        den.aspects.zsh
        den.aspects.ghostty
        den.aspects.btop
        den.aspects.cli-apps
        den.aspects.stylix

        # Applications (common to all hosts).
        den.aspects.element
        den.aspects.signal
        den.aspects.vesktop
        den.aspects.whatsapp
        den.aspects.ente-desktop
        den.aspects.spotify
        den.aspects.joplin
        den.aspects.obsidian
        den.aspects.ente-auth
        den.aspects.bitwarden
        den.aspects.filen-desktop
        den.aspects.claude-code
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
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFCIJ1LhkFDBZaZU/bf8Y3XyCXb3RnVxg4gRs6i+XbSe tomwrw"
              #"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC1jQK1qY7I0ll2Cn+0+D7ilaveL5K07ftRcBx/k6cFK tomwrw"
            ];
            # Filter to groups that actually exist on this host, so host-specific
            # groups (e.g. `libvirtd`, present only where virtualisation is
            # enabled = endgame) are silently skipped elsewhere — one list, no
            # per-host variants, no dead entries.
            extraGroups = builtins.filter (g: builtins.hasAttr g config.users.groups) [
              "disk"
              "i2c"
              "networkmanager"
              "wheel"
              "libvirtd" # virt-manager (endgame only)
              "kvm" # /dev/kvm access
              "video" # GPU / camera
              "render" # GPU render nodes
              "audio" # direct audio device access
              "input" # input devices (evdev)
              "plugdev" # pluggable devices (USB)
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

          # HM user-global boilerplate (applies on every host / standalone HM).
          systemd.user.startServices = "sd-switch";
          programs.home-manager.enable = true;
          home.sessionPath = [ "$HOME/.local/bin" ];

          programs.git.settings.user.name = "tomwrw";
          programs.git.settings.user.email = "tomwrw@proton.me";
        };

      provides.endgame = {
        includes = [
          den.aspects.gaming
          den.aspects.code-cursor
          den.aspects.gemini
          den.aspects.emulation
        ];
      };
    };
}
