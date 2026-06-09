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

          sops.secrets."users/tomwrw/password".neededForUsers = true;

          users.users.tomwrw = {
            hashedPasswordFile = config.sops.secrets."users/tomwrw/password".path;
            openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFCIJ1LhkFDBZaZU/bf8Y3XyCXb3RnVxg4gRs6i+XbSe tomwrw"
            ];

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
