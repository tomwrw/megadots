{
  den,
  ...
}:
{
  den.aspects.tomwrw = {

    includes = [
      den.batteries.primary-user
      (den.batteries.user-shell "zsh")
      den.aspects.sops
      den.aspects.ssh
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
      den.aspects.vscodium
      den.aspects.proton-suite
    ];

    nixos =
      {
        config,
        ...
      }:
      {
        users.mutableUsers = false;

        sops.secrets."users/tomwrw/password".neededForUsers = true;

        users.users.tomwrw = {
          hashedPasswordFile = config.sops.secrets."users/tomwrw/password".path;
          openssh.authorizedKeys.keys = [
            # Token2 FIDO2 hardware keys (resident, PIN + touch per use).
            # The legacy file-based key was retired 2026-06-12.
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPiQIe8ejl2D9ZLBZCHYyt7Iyh9jFHZ5iMYydq57DnDSAAAACnNzaDp0b213cnc= tomwrw-primary"
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIG+ODAzUIgoEOgf1+ijqOPCljmYoXn9HETmJ1kP5cuAFAAAACnNzaDp0b213cnc= tomwrw-backup"
          ];

          # wheel + networkmanager come from the primary-user battery.
          extraGroups = builtins.filter (g: builtins.hasAttr g config.users.groups) [
            "disk"
            "i2c"
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
              /home/tomwrw/.ssh/id_ed25519_sk_primary \
              /home/tomwrw/.ssh/id_ed25519_sk_primary.pub \
              /home/tomwrw/.ssh/id_ed25519_sk_backup \
              /home/tomwrw/.ssh/id_ed25519_sk_backup.pub || true
          '';
        };
      };

    homeManager = _: {
      # home.username / home.homeDirectory come from the define-user battery;
      # home.stateVersion from den.default.
      systemd.user.startServices = "sd-switch";
      programs.home-manager.enable = true;
      home.sessionPath = [ "$HOME/.local/bin" ];

      programs.git.settings.user.name = "tomwrw";
      programs.git.settings.user.email = "tomwrw@proton.me";

      # SSH signer identities for commit-signature verification. Lives with the
      # user (not the git aspect) because it is pure identity — this user's
      # email mapped to their specific keys. git.nix sets the file path.
      xdg.configFile."git/allowed_signers".text = ''
        tomwrw@proton.me sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIPiQIe8ejl2D9ZLBZCHYyt7Iyh9jFHZ5iMYydq57DnDSAAAACnNzaDp0b213cnc= tomwrw-primary
        tomwrw@proton.me sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIG+ODAzUIgoEOgf1+ijqOPCljmYoXn9HETmJ1kP5cuAFAAAACnNzaDp0b213cnc= tomwrw-backup
        # Retired 2026-06-12; kept so signatures on older commits still verify.
        tomwrw@proton.me ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFCIJ1LhkFDBZaZU/bf8Y3XyCXb3RnVxg4gRs6i+XbSe tomwrw-legacy
      '';
    };

    provides.endgame = {
      includes = [
        # gaming is also a host aspect on endgame (its nixos side → steam);
        # this user inclusion is what routes its homeManager side (mangohud)
        # to tomwrw — not redundant.
        den.aspects.gaming
        den.aspects.code-cursor
        den.aspects.gemini
        den.aspects.emulation
      ];
    };
  };
}
